module TurtleGraphics

  class Turtle

    attr_accessor :row, :column, :orientation,
                  :canvas, :x, :y

    def initialize(row, column)
      @row, @column = row, column
      @orientation = :right
      @canvas = Array.new(@row) { Array.new(@column, 0) }
      spawn_at(0, 0)
    end

    def draw(*arg, &block)
      instance_eval &block
      if arg[0]
        arg[0].draw(@canvas)
      else
        @canvas
      end
    end

    def look(orientation)
      @orientation = orientation
    end

    def spawn_at(row, column)
      @y = row
      @x = column
      visit
    end

    def turn_left
      @orientation = case @orientation
      when :up then :left
      when :left then :down
      when :down then :right
      when :right then :up
      end
    end

    def turn_right

      @orientation = case @orientation
      when :up then :right
      when :right then :down
      when :down then :left
      when :left then :up
      end

    end

    def move

      movements = {
        right: [ 1, 0 ],
        down: [ 0, 1],
        left: [ -1, 0 ],
        up: [ 0, -1 ]
      }
      @x += movements[@orientation][0]
      @y += movements[@orientation][1]

      inbound

      visit
    end

    def inbound

      if @x > @column - 1 or @x < 0
        @x = 0
      elsif @y > @row - 1 or @y < 0
        @y = 0
      end

    end

    def visit
      @canvas[@y][@x] += 1
    end

  end

  module Canvas

    class ASCII

      attr_accessor :symbols, :intensive

      def initialize(symbols)
        @symbols = symbols
      end

      def intensive_symbol(intensive)

        index = (intensive * (symbols.length - 1)).ceil
        @symbols[index]

      end

      def draw(canvas)

        max_value = canvas.flatten.max
        canvas.each do |row|
          row.each do |value|
            intensive = value.to_f / max_value
            print intensive_symbol(intensive)
          end
          print "\n"
        end

      end

    end

    class HTML

      def initialize(pixels)
        @pixels = pixels
      end

      def draw(canvas)
        html = draw_header
        html += draw_css
        html += draw_table(canvas)
        html += draw_footer
      end

      def draw_header
        return "<!DOCTYPE html>
<html>
<head>
  <title>Turtle graphics</title>"
      end

      def draw_css
        return "<style>
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
</style>"
      end

      def draw_table(canvas)
        max_value, table = canvas.flatten.max, "<body><table>"
        canvas.each do |row|
          table += "<tr>" + "\n"
          row.each do |value|
            intensive = value.to_f / max_value
            table += "<td style= \"opacity: #{intensive.round(2)}\"></td>" + "\n"
          end
          table += "</tr>" + "\n"
        end
        table += "</table>"
        return table
      end

      def draw_footer
        return "</body>
</html>"
      end

    end

  end
end
