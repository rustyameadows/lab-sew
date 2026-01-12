module Patterns
  class SvgRenderer
    def initialize(geometry, scale: 24, gap: 24, padding: 24, corner_radius: 0)
      @geometry = geometry || {}
      @scale = scale
      @gap = gap
      @padding = padding
      @corner_radius = corner_radius
    end

    def call
      panels = Array(@geometry[:panels] || @geometry["panels"])
      return empty_svg if panels.empty?

      sizes = panels.map do |panel|
        {
          key: panel[:key] || panel["key"],
          label: panel[:label] || panel["label"],
          width: (panel[:width] || panel["width"]).to_f * @scale,
          height: (panel[:height] || panel["height"]).to_f * @scale
        }
      end

      columns = 2
      col_widths = Array.new(columns, 0.0)
      row_heights = []

      sizes.each_with_index do |panel, index|
        col = index % columns
        row = index / columns
        col_widths[col] = [col_widths[col], panel[:width]].max
        row_heights[row] = [row_heights[row] || 0.0, panel[:height]].max
      end

      total_width = col_widths.sum + @gap * (columns - 1) + @padding * 2
      total_height = row_heights.sum + @gap * ([row_heights.size - 1, 0].max) + @padding * 2

      rects = []
      labels = []
      y = @padding

      row_heights.each_with_index do |row_height, row_index|
        x = @padding
        (0...columns).each do |col_index|
          panel_index = row_index * columns + col_index
          panel = sizes[panel_index]
          break unless panel

          rects << rect_element(x, y, panel[:width], panel[:height])
          labels << text_element(x + 8, y + 18, panel[:label] || panel[:key])
          # Labels are rendered in the UI below the SVG thumbnails.
          x += col_widths[col_index] + @gap
        end
        y += row_height + @gap
      end

      <<~SVG
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 #{total_width} #{total_height}" width="#{total_width}" height="#{total_height}">
          <rect x="0" y="0" width="#{total_width}" height="#{total_height}" fill="#fbfaf8" />
          #{rects.join("\n")}
          #{labels.join("\n")}
        </svg>
      SVG
    end

    private

    def rect_element(x, y, width, height)
      %(<rect x="#{x}" y="#{y}" width="#{width}" height="#{height}" fill="#ffffff" stroke="#c9c3bb" stroke-width="2" rx="0" ry="0" stroke-linejoin="miter" />)
    end

    def text_element(x, y, label)
      safe_label = label.to_s.gsub("&", "&amp;").gsub("<", "&lt;").gsub(">", "&gt;")
      %(<text x="#{x}" y="#{y}" font-family="system-ui, sans-serif" font-size="14" fill="#6b6460">#{safe_label}</text>)
    end

    def empty_svg
      <<~SVG
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 400 240" width="400" height="240">
          <rect x="0" y="0" width="400" height="240" fill="#fbfaf8" />
          <text x="20" y="40" font-family="system-ui, sans-serif" font-size="14" fill="#6b6460">No panels defined</text>
        </svg>
      SVG
    end
  end
end
