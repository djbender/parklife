# frozen_string_literal: true
require 'parklife/reporter/progress'
require 'parklife/route'

RSpec.describe Parklife::Reporter::Progress do
  subject { described_class.new(logger) }

  let(:logger) { instance_double(Parklife::Logger) }
  let(:route) { Parklife::Route.new('/foo', crawl: false) }
  let(:response) { Rack::MockResponse.new(200, {}, '') }

  before do
    allow(logger).to receive(:colour).with('.', :green).and_return('.')
    allow(logger).to receive(:print)
    allow(logger).to receive(:puts)
  end

  describe '#visit' do
    it 'prints a coloured dot' do
      subject.visit(route, response)
      expect(logger).to have_received(:print).with('.')
    end
  end

  describe '#finish' do
    it 'prints a newline' do
      subject.finish
      expect(logger).to have_received(:puts)
    end
  end
end
