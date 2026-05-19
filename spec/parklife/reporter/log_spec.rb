# frozen_string_literal: true
require 'parklife/reporter/log'
require 'parklife/route'

RSpec.describe Parklife::Reporter::Log do
  subject { described_class.new(logger) }

  let(:logger) { instance_double(Parklife::Logger) }
  let(:route) { Parklife::Route.new('/foo', crawl: false) }
  let(:response) { Rack::MockResponse.new(200, {}, '') }

  before do
    allow(logger).to receive(:colour).with(200, :green).and_return('200')
    allow(logger).to receive(:puts)
  end

  describe '#visit' do
    it 'outputs the status and path' do
      subject.visit(route, response)
      expect(logger).to have_received(:puts).with('200 /foo')
    end
  end
end
