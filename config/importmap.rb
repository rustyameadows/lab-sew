# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin "three", to: "https://unpkg.com/three@0.161.0/build/three.module.js"
pin "three/addons/controls/OrbitControls", to: "https://unpkg.com/three@0.161.0/examples/jsm/controls/OrbitControls.js"
pin_all_from "app/javascript/controllers", under: "controllers"
