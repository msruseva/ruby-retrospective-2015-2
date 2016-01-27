class Spreadsheet
  class Error < RuntimeError
  end

  def initialize(data = '')
    @cells = data.strip.split(/\n/).map do |row|
      row.strip.split(/\t|\s{2,}/).map(&:strip)
    end
    @rows = @cells.size
  end

  def empty?
    @cells.empty?
  end

  def cell_at(index)
    cell = Cell.new(index)
    assert_cell_exists cell
    @cells[cell.row][cell.column]
  end

  def [](index)
    Expressions.evaluate_string(cell_at(index), self)
  end

  def to_s
    (0...@rows).map { |row| row_to_s(row) }.join("\n")
  end

  private

  def assert_cell_exists(cell)
    unless cell.row < @rows and cell.column < @cells[cell.row].size
      raise Error, "Cell '#{cell}' does not exist"
    end
  end

  def row_to_s(row)
    values = (0...@cells[row].size).map do |column|
      Expressions.evaluate_string(@cells[row][column], self)
    end

    values.join("\t")
  end
end

class Spreadsheet
  class Cell
    LETTERS = 'Z'.ord - 'A'.ord + 1
    PATTERN = /\A([A-Z]+)(\d+)\z/

    def Cell.cell?(string)
      string =~ PATTERN
    end

    attr_reader :row, :column

    def initialize(index)
      assert_cell(index)
      @index = index
      @row, @column = to_numbers(index)
    end

    def to_s
      @index
    end

    private

    def assert_cell(index)
      unless Cell.cell? index
        raise Error, "Invalid cell index '#{index}'"
      end
    end

    def to_numbers(index)
      column, row = index.match(PATTERN).captures
      row = row.to_i.pred
      column = column.split(//).reverse.each_with_index
        .map { |c, i| (c.ord - 'A'.ord + 1) * LETTERS ** i }
        .reduce(&:+).pred
      [row, column]
    end
  end
end

class Spreadsheet
  module Formulas
    ARGUMENTS_ERROR = "Wrong number of arguments for '%s': %s"

    module_function

    def add(args, sheet)
      assert_at_least('ADD', 2, args.size)
      calculate(args, sheet, :+)
    end

    def subtract(args, sheet)
      assert_exactly('SUBTRACT', 2, args.size)
      calculate(args, sheet, :-)
    end

    def multiply(args, sheet)
      assert_at_least('MULTIPLY', 2, args.size)
      calculate(args, sheet, :*)
    end

    def divide(args, sheet)
      assert_exactly('DIVIDE', 2, args.size)
      calculate(args, sheet, :/)
    end

    def mod(args, sheet)
      assert_exactly('MOD', 2, args.size)
      calculate(args, sheet, :%)
    end

    def calculate(args, sheet, function)
      values = args.map do |argument|
        Expressions.evaluate_expression(argument, sheet)
      end
      values[1 .. -1].map(&:to_f).reduce(values[0].to_f, &function)
    end

    def assert_at_least(name, expected, actual)
      if actual < expected
        raise Error, ARGUMENTS_ERROR %
          [name, "expected at least #{expected}, got #{actual}"]
      end
    end

    def assert_exactly(name, expected, actual)
      if actual != expected
        raise Error, ARGUMENTS_ERROR %
          [name, "expected #{expected}, got #{actual}"]
      end
    end
  end
end

class Spreadsheet
  class Formula
    PATTERN = /\A([A-Z]+)\(([^\)]*)\)\z/

    def Formula.formula?(string)
      string =~ PATTERN
    end

    def initialize(string)
      if string !~ PATTERN
        raise Error, "Invalid expression '#{string}'"
      end

      @name, args = string.match(PATTERN).captures
      @args = args.split(/\s*,\s*/)
    end

    def value(sheet)
      case @name
      when 'ADD', 'MULTIPLY', 'SUBTRACT', 'DIVIDE', 'MOD'
        formula = @name.downcase.to_sym
        Formulas.send(formula, @args, sheet)
      else
        raise Error, "Unknown function '#{@name}'"
      end
    end
  end
end

class Spreadsheet
  module Expressions
    module_function

    def expression?(string)
      string.start_with? '='
    end

    def evaluate_string(cell, sheet)
      unless expression?(cell)
        return cell
      end

      evaluate_expression(cell[1 .. -1], sheet)
    end

    def evaluate_expression(cell, sheet)
      evaluate_safely(cell, sheet) or
        raise Error, "Invalid expression '#{cell}'"
    end

    def evaluate_safely(cell, sheet)
      case
      when Cell.cell?(cell)
        sheet[cell]
      when Formula.formula?(cell)
        format(Formula.new(cell).value(sheet))
      when number?(cell)
        format(cell.to_f)
      end
    end

    def number?(cell)
      return cell =~ /\A[+-]?[0-9]+(\.[0-9]+)?\z/
    end

    def format(x)
      (x % 1 == 0) ? (x.to_i.to_s) : ("%.2f" % x)
    end
  end
end
