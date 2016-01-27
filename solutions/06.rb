module TurtleGraphics

  module Canvas

    class Matrix
      def draw(canvas)
        canvas
      end
    end

    attr_accessor :symbols

    class ASCII
      def initialize(symbols)
        @symbols = symbols
      end

      def draw(canvas)
        max_value = canvas.map(&:max).max

        canvas.map do |row|
          row.map do |value|
            intensive_symbol(value.to_f / max_value)
          end.join('')
        end.join("\n")
      end

      def intensive_symbol(intensive)
        index = (intensive * (@symbols.length - 1)).ceil
        @symbols[index]
      end
    end

    class HTML
      def initialize(pixels)
        @pixels = pixels
      end

      def draw(canvas)
        "<!DOCTYPE html>
        <html>#{draw_header}#{draw_body(canvas)}</html>"
      end

      def draw_header
        "<head>
          <title>Turtle graphics</title>
          <style>
            table {
              border-spacing: 0;
            }
            tr {
              padding: 0;
            }
            td {
              width: #{@pixels}px;
              height: #{@pixels}px;
              background-color: black;
              padding: 0;
            }
          </style>
        </head>"
      end

      def draw_body(canvas)
        "<body><table>#{draw_table(canvas)}</table></body>"
      end

      def draw_table(canvas)
        max_intensity = canvas.map(&:max).max.to_f

        canvas.map do |row|
          columns = row.map do |intensity|
            '<td style="opacity: %.2f"></td>' % (intensity / max_intensity)
          end

          "<tr>#{columns.join('')}</tr>"
        end.join('')
      end
    end
  end

  class Turtle
    ORIENTATIONS = [:left, :up, :right, :down].freeze

    def initialize(rows, columns)
      @canvas = Array.new(rows) { Array.new(columns, 0)}

      @rows, @columns = rows, columns
      @orientation = :right
      spawn_at(0,0)
    end

    def draw(canvas = Canvas::Matrix.new, &block)
      instance_eval &block

      @canvas[@y][@x] += 1

      canvas.draw(@canvas)
    end

    private

    def spawn_at(row, column)
      @y = row
      @x = column
    end

    def look(orientation)
      @orientation = orientation
    end

    def move
      @canvas[@y][@x] += 1

      case @orientation
        when :left  then @x -= 1
        when :up    then @y -= 1
        when :right then @x += 1
        when :down  then @y += 1
      end

      @y %= @rows
      @x %= @columns
    end

    def turn_left
      @orientation = ORIENTATIONS[(ORIENTATIONS.find_index(@orientation) - 1) % 4]
    end

    def turn_right
      @orientation = ORIENTATIONS[(ORIENTATIONS.find_index(@orientation) + 1) % 4]
    end
  end
end
