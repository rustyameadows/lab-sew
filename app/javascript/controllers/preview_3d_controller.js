import { Controller } from "@hotwired/stimulus"
import * as THREE from "three"
import { OrbitControls } from "three/addons/controls/OrbitControls"

export default class extends Controller {
  static targets = ["canvas"]
  static values = {
    geometryUrl: String
  }

  connect() {
    if (!this.hasCanvasTarget) return

    this.scene = new THREE.Scene()
    this.camera = new THREE.PerspectiveCamera(45, 1, 0.1, 100)
    this.camera.position.set(3.2, 2.6, 4.2)
    this.renderer = new THREE.WebGLRenderer({ canvas: this.canvasTarget, antialias: true })
    this.renderer.setPixelRatio(window.devicePixelRatio || 1)
    this.renderer.setClearColor("#fbfaf8")

    this.controls = new OrbitControls(this.camera, this.renderer.domElement)
    this.controls.enableDamping = true
    this.onControlsStart = () => {
      this.cameraAuto = false
      this.desiredCameraPos = null
    }
    this.controls.addEventListener("start", this.onControlsStart)

    const ambient = new THREE.AmbientLight(0xffffff, 0.9)
    this.scene.add(ambient)
    const directional = new THREE.DirectionalLight(0xffffff, 0.6)
    directional.position.set(4, 6, 3)
    this.scene.add(directional)

    this.panelGroup = new THREE.Group()
    this.scene.add(this.panelGroup)

    this.progress = 1
    this.targetProgress = 1
    this.meshes = []
    this.desiredCameraPos = null
    this.desiredTarget = new THREE.Vector3()
    this.cameraInitialized = false
    this.cameraAuto = false

    this.onResize = this.resize.bind(this)
    window.addEventListener("resize", this.onResize)
    this.onParamsUpdated = this.reloadGeometry.bind(this)
    window.addEventListener("design-session-params:updated", this.onParamsUpdated)

    this.reloadGeometry()
    this.animate()
  }

  disconnect() {
    if (this.controls && this.onControlsStart) {
      this.controls.removeEventListener("start", this.onControlsStart)
    }
    window.removeEventListener("resize", this.onResize)
    window.removeEventListener("design-session-params:updated", this.onParamsUpdated)
  }

  async reloadGeometry() {
    if (!this.geometryUrlValue) return
    const response = await fetch(this.geometryUrlValue, { cache: "no-store" })
    const data = await response.json()
    this.geometry = data
    this.buildPanels()
  }

  toggle() {
    this.targetProgress = this.targetProgress < 0.5 ? 1 : 0
    const isFlat = this.targetProgress < 0.5
    const targetBox = isFlat ? this.flatBox : this.assembledBox
    if (targetBox) this.fitCameraToBox(targetBox, isFlat ? "flat" : "assembled", false)
    this.animateTransition()
  }

  animateTransition() {
    if (this.animating) return
    this.animating = true
    const start = performance.now()
    const from = this.progress
    const to = this.targetProgress
    const duration = 600

    const step = (time) => {
      const t = Math.min((time - start) / duration, 1)
      const ease = t * (2 - t)
      this.progress = from + (to - from) * ease
      if (t < 1) {
        requestAnimationFrame(step)
      } else {
        this.animating = false
      }
    }

    requestAnimationFrame(step)
  }

  buildPanels() {
    this.panelGroup.clear()
    this.meshes = []
    if (!this.geometry) return

    const panels = this.geometry.panels || []
    const preview3d = this.geometry.preview_3d || {}
    const seamDefs = Array(preview3d.seams || this.geometry.seams || [])
    const params = this.geometry.params || {}
    const roleMap = preview3d.panels || {}
    const meshDefs = panels.map((panel) => ({
      panel,
      key: panel.key,
      role: roleMap[panel.key]?.role
    }))
    const panelMap = new Map(meshDefs.map((def) => [def.key, def.panel]))

    const unitScale = 0.1
    const gap = 0.2
    const columns = 2
    const flatPositions = this.flatLayout(meshDefs.map((def) => def.panel), unitScale, gap, columns)
    const assembledMap = this.assembleBySeams(panelMap, seamDefs, preview3d.root, unitScale)
    this.alignDepthCenter(assembledMap, preview3d, params, unitScale)

    const items = meshDefs.map((def, index) => {
      const flat = flatPositions[index] || {
        position: new THREE.Vector3(),
        quaternion: new THREE.Quaternion()
      }
      const assembled = assembledMap[def.key] || this.assembledTransform(def, preview3d, params, unitScale)
      return { def, flat, assembled }
    })

    const assembledBoxRaw = this.boundingBoxFor(items, unitScale, "assembled")
    const flatBoxRaw = this.boundingBoxFor(items, unitScale, "flat")
    const assembledCenter = assembledBoxRaw.getCenter(new THREE.Vector3())
    const flatCenter = flatBoxRaw.getCenter(new THREE.Vector3())

    items.forEach((item) => {
      const panel = item.def.panel
      const width = (panel.width || 0) * unitScale
      const height = (panel.height || 0) * unitScale
      const geometry = new THREE.PlaneGeometry(width, height)
      const material = new THREE.MeshBasicMaterial({ color: 0xdbe9ff, side: THREE.DoubleSide })
      material.polygonOffset = true
      material.polygonOffsetFactor = 1
      material.polygonOffsetUnits = 1
      const mesh = new THREE.Mesh(geometry, material)

      const edges = new THREE.LineSegments(
        new THREE.EdgesGeometry(geometry),
        new THREE.LineBasicMaterial({ color: 0xb9b2aa, depthTest: true, depthWrite: true })
      )
      edges.renderOrder = 1
      mesh.add(edges)

      item.flat.position.sub(flatCenter)
      item.assembled.position.sub(assembledCenter)

      this.meshes.push({ mesh, edges, flat: item.flat, assembled: item.assembled })
      this.panelGroup.add(mesh)
    })

    this.assembledBox = this.boundingBoxFor(items, unitScale, "assembled")
    this.flatBox = this.boundingBoxFor(items, unitScale, "flat")
    if (!this.cameraInitialized) {
      this.fitCameraToBox(this.assembledBox, "assembled", true)
    }

    this.resize()
  }

  flatLayout(panels, unitScale, gap, columns) {
    const sizes = panels.map((panel) => ({
      width: (panel.width || 0) * unitScale,
      height: (panel.height || 0) * unitScale
    }))

    const colWidths = Array.from({ length: columns }, () => 0)
    const rowHeights = []
    sizes.forEach((panel, index) => {
      const col = index % columns
      const row = Math.floor(index / columns)
      colWidths[col] = Math.max(colWidths[col], panel.width)
      rowHeights[row] = Math.max(rowHeights[row] || 0, panel.height)
    })

    const positions = []
    let y = 0
    rowHeights.forEach((rowHeight, rowIndex) => {
      let x = 0
      for (let col = 0; col < columns; col += 1) {
        const panelIndex = rowIndex * columns + col
        const panel = sizes[panelIndex]
        if (!panel) break
        positions[panelIndex] = {
          position: new THREE.Vector3(x + panel.width / 2, -y - panel.height / 2, 0),
          quaternion: new THREE.Quaternion()
        }
        x += colWidths[col] + gap
      }
      y += rowHeight + gap
    })

    return positions
  }

  assembledTransform(def, preview3d, params, unitScale) {
    const role = def.role
    if (!role) {
      return { position: new THREE.Vector3(), quaternion: new THREE.Quaternion() }
    }

    const width = (params[preview3d.width_param] || 0) * unitScale
    const height = (params[preview3d.height_param] || 0) * unitScale
    const depth = (params[preview3d.depth_param] || 0) * unitScale

    const halfW = width / 2
    const halfH = height / 2
    const halfD = depth / 2

    switch (role) {
      case "front":
        return {
          position: new THREE.Vector3(0, 0, halfD),
          quaternion: new THREE.Quaternion()
        }
      case "back":
        return {
          position: new THREE.Vector3(0, 0, -halfD),
          quaternion: new THREE.Quaternion().setFromEuler(new THREE.Euler(0, Math.PI, 0))
        }
      case "bottom":
        return {
          position: new THREE.Vector3(0, -halfH, 0),
          quaternion: new THREE.Quaternion().setFromEuler(new THREE.Euler(-Math.PI / 2, 0, 0))
        }
      case "top":
        return {
          position: new THREE.Vector3(0, halfH, 0),
          quaternion: new THREE.Quaternion().setFromEuler(new THREE.Euler(Math.PI / 2, 0, 0))
        }
      case "side":
        return {
          position: new THREE.Vector3(halfW, 0, 0),
          quaternion: new THREE.Quaternion().setFromEuler(new THREE.Euler(0, Math.PI / 2, 0))
        }
      case "side_left":
        return {
          position: new THREE.Vector3(-halfW, 0, 0),
          quaternion: new THREE.Quaternion().setFromEuler(new THREE.Euler(0, -Math.PI / 2, 0))
        }
      case "strap":
        return {
          position: new THREE.Vector3(0, halfH + 0.05, 0),
          quaternion: new THREE.Quaternion().setFromEuler(new THREE.Euler(Math.PI / 2, 0, 0))
        }
      default:
        return { position: new THREE.Vector3(), quaternion: new THREE.Quaternion() }
    }
  }

  resize() {
    if (!this.renderer) return
    const container = this.canvasTarget?.parentElement || this.element
    const { clientWidth, clientHeight } = container
    const width = clientWidth || 400
    const height = clientHeight || 280
    this.renderer.setSize(width, height, false)
    this.camera.aspect = width / height
    this.camera.updateProjectionMatrix()
  }

  animate() {
    if (!this.renderer) return
    requestAnimationFrame(() => this.animate())

    this.meshes.forEach(({ mesh, flat, assembled }) => {
      mesh.position.lerpVectors(flat.position, assembled.position, this.progress)
      mesh.quaternion.slerpQuaternions(flat.quaternion, assembled.quaternion, this.progress)
    })

    if (this.cameraAuto && this.desiredCameraPos) {
      this.camera.position.lerp(this.desiredCameraPos, 0.12)
      this.controls.target.lerp(this.desiredTarget, 0.12)
      if (
        this.camera.position.distanceTo(this.desiredCameraPos) < 0.01 &&
        this.controls.target.distanceTo(this.desiredTarget) < 0.01
      ) {
        this.cameraAuto = false
      }
    }

    this.controls.update()
    this.renderer.render(this.scene, this.camera)
  }

  assembleBySeams(panelMap, seams, rootKey, unitScale) {
    if (!panelMap || panelMap.size === 0) return {}

    const root = rootKey || panelMap.keys().next().value
    if (!root) return {}

    const seamsByParent = new Map()
    seams.forEach((seam) => {
      if (!seam.parent || !seam.child) return
      if (!seamsByParent.has(seam.parent)) {
        seamsByParent.set(seam.parent, [])
      }
      seamsByParent.get(seam.parent).push(seam)
    })

    const transforms = {
      [root]: { position: new THREE.Vector3(), quaternion: new THREE.Quaternion() }
    }
    const queue = [root]

    while (queue.length > 0) {
      const parentKey = queue.shift()
      const parentPanel = panelMap.get(parentKey)
      const parentTransform = transforms[parentKey]
      if (!parentPanel || !parentTransform) continue

      const parentSeams = seamsByParent.get(parentKey) || []
      parentSeams.forEach((seam) => {
        const childKey = seam.child
        if (transforms[childKey]) return
        const childPanel = panelMap.get(childKey)
        if (!childPanel) return

        const childTransform = this.transformFromSeam(
          parentPanel,
          childPanel,
          parentTransform,
          seam,
          unitScale
        )
        transforms[childKey] = childTransform
        queue.push(childKey)
      })
    }

    return transforms
  }

  transformFromSeam(parentPanel, childPanel, parentTransform, seam, unitScale) {
    const parentEdgePoint = this.edgePoint(parentPanel, seam.parent_edge, unitScale)
    const childEdgePoint = this.edgePoint(childPanel, seam.child_edge, unitScale)
    const hingeAxis = this.edgeAxis(seam.parent_edge)
    const angle = THREE.MathUtils.degToRad(seam.angle || 0)

    const align = parentEdgePoint.clone().sub(childEdgePoint)
    const pivot = parentEdgePoint

    const alignMatrix = new THREE.Matrix4().makeTranslation(align.x, align.y, align.z)
    const pivotMatrix = new THREE.Matrix4().makeTranslation(pivot.x, pivot.y, pivot.z)
    const pivotInverse = new THREE.Matrix4().makeTranslation(-pivot.x, -pivot.y, -pivot.z)
    const rotationMatrix = new THREE.Matrix4().makeRotationAxis(hingeAxis, angle)

    const localMatrix = new THREE.Matrix4()
    localMatrix.multiplyMatrices(pivotMatrix, rotationMatrix)
    localMatrix.multiply(pivotInverse)
    localMatrix.multiply(alignMatrix)

    const parentMatrix = new THREE.Matrix4().compose(
      parentTransform.position,
      parentTransform.quaternion,
      new THREE.Vector3(1, 1, 1)
    )
    const worldMatrix = new THREE.Matrix4().multiplyMatrices(parentMatrix, localMatrix)

    const position = new THREE.Vector3()
    const quaternion = new THREE.Quaternion()
    const scale = new THREE.Vector3()
    worldMatrix.decompose(position, quaternion, scale)

    return { position, quaternion }
  }

  edgePoint(panel, edge, unitScale) {
    const width = (panel.width || 0) * unitScale
    const height = (panel.height || 0) * unitScale

    switch (edge) {
      case "left":
        return new THREE.Vector3(-width / 2, 0, 0)
      case "right":
        return new THREE.Vector3(width / 2, 0, 0)
      case "top":
        return new THREE.Vector3(0, height / 2, 0)
      case "bottom":
        return new THREE.Vector3(0, -height / 2, 0)
      default:
        return new THREE.Vector3()
    }
  }

  edgeAxis(edge) {
    switch (edge) {
      case "left":
      case "right":
        return new THREE.Vector3(0, 1, 0)
      case "top":
      case "bottom":
        return new THREE.Vector3(1, 0, 0)
      default:
        return new THREE.Vector3(0, 1, 0)
    }
  }

  centerOf(positions) {
    if (!positions.length) return new THREE.Vector3()
    const sum = new THREE.Vector3()
    positions.forEach((position) => sum.add(position))
    return sum.multiplyScalar(1 / positions.length)
  }

  boundingBoxFor(items, unitScale, mode) {
    const box = new THREE.Box3()
    items.forEach((item) => {
      const transform = mode === "flat" ? item.flat : item.assembled
      if (!transform) return
      const panel = item.def.panel
      const width = (panel.width || 0) * unitScale
      const height = (panel.height || 0) * unitScale
      const halfW = width / 2
      const halfH = height / 2

      const corners = [
        new THREE.Vector3(-halfW, -halfH, 0),
        new THREE.Vector3(halfW, -halfH, 0),
        new THREE.Vector3(halfW, halfH, 0),
        new THREE.Vector3(-halfW, halfH, 0)
      ]

      corners.forEach((corner) => {
        corner.applyQuaternion(transform.quaternion).add(transform.position)
        box.expandByPoint(corner)
      })
    })

    return box
  }

  fitCameraToBox(box, mode, instant) {
    if (!this.camera) return
    const size = box.getSize(new THREE.Vector3())
    const maxDim = Math.max(size.x, size.y, size.z)
    const fov = THREE.MathUtils.degToRad(this.camera.fov)
    const distance = maxDim / (2 * Math.tan(fov / 2))
    const padding = 1.4
    const center = box.getCenter(new THREE.Vector3())
    const direction =
      mode === "flat" ? new THREE.Vector3(0, 0, 1) : new THREE.Vector3(1, 0.8, 1.2).normalize()
    const nextPos = center.clone().add(direction.multiplyScalar(distance * padding))
    this.camera.near = Math.max(0.01, distance / 100)
    this.camera.far = distance * 100
    this.camera.updateProjectionMatrix()

    if (this.controls) {
      this.desiredCameraPos = nextPos
      this.desiredTarget.copy(center)
      if (instant || !this.cameraInitialized) {
        this.camera.position.copy(nextPos)
        this.controls.target.copy(center)
        this.controls.update()
        this.cameraInitialized = true
        this.cameraAuto = false
      } else {
        this.cameraAuto = true
      }
    }
  }

  alignDepthCenter(transforms, preview3d, params, unitScale) {
    if (!transforms || !preview3d) return
    const depthParam = preview3d.depth_param
    if (!depthParam) return
    const depth = Number(params[depthParam]) * unitScale
    if (!Number.isFinite(depth) || depth <= 0) return

    const roleMap = preview3d.panels || {}
    let frontKey = null
    let backKey = null
    Object.keys(roleMap).forEach((key) => {
      const role = roleMap[key]?.role
      if (role === "front") frontKey = key
      if (role === "back") backKey = key
    })

    const front = frontKey ? transforms[frontKey] : null
    const back = backKey ? transforms[backKey] : null
    let shiftZ = null
    if (front) {
      shiftZ = depth / 2 - front.position.z
    } else if (back) {
      shiftZ = -depth / 2 - back.position.z
    }

    if (shiftZ === null) return
    Object.values(transforms).forEach((transform) => {
      transform.position.z += shiftZ
    })
  }
}
