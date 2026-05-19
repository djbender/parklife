# frozen_string_literal: true
require 'forwardable'
require 'thor/shell/color'

module Parklife
  class Logger
    extend Forwardable

    attr_accessor :no_colour

    def initialize(stdout = nil, stderr = nil, no_colour: false)
      @stdout = stdout
      @stderr = stderr
      @no_colour = no_colour
      @thor_color = Thor::Shell::Color.new
    end

    def stderr = @stderr || $stderr
    def stdout = @stdout || $stdout

    def print(*args) = stdout.print(*args)
    def puts(*args) = stdout.puts(*args)

    def colour(string, *colours)
      no_colour ? string : @thor_color.set_color(string, *colours)
    end

    def warn(*message)
      stderr.puts(colour(*message, :on_red))
    end
  end
end
