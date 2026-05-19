require 'parklife/cli'

RSpec.describe Parklife::CLI do
  let(:tmpdir) { Dir.mktmpdir }

  around do |example|
    Dir.chdir(tmpdir) { example.run }
  end

  after do
    FileUtils.remove_entry_secure(tmpdir)
  end

  before do
    allow(Parklife).to receive(:application).and_return(Parklife::Application.new)
  end

  describe 'init' do
    subject { described_class.new.invoke(:init, [], options) }

    context 'with no args' do
      let(:options) { {} }

      it do
        expect { subject }.to output.to_stdout
          .and change { File.exist?('Parkfile') }.to(true)
          .and change { File.exist?('bin/static-build') }.to(true)

        expect(File.executable?('bin/static-build')).to be(true)
      end
    end

    context '--rails' do
      let(:options) { { rails: true } }

      it do
        expect { subject }.to output.to_stdout

        expect(File.read('Parkfile')).to include(
          "require_relative 'config/environment'",
          'feed_path(format: :atom)'
        )

        expect(File.read('bin/static-build'))
          .to include('rails assets:precompile')
      end
    end

    context '--sinatra' do
      let(:options) { { sinatra: true } }

      it do
        expect { subject }.to output.to_stdout

        expect(File.read('Parkfile')).to include('Sinatra::Application')

        expect(File.read('bin/static-build'))
          .to include('APP_ENV=production')
      end
    end

    context '--github-pages' do
      let(:options) { { github_pages: true } }

      it do
        expect { subject }.to output.to_stdout
          .and change { File.exist?('.github/workflows/parklife.yml') }.to(true)

        expect(File.read('Parkfile')).to include('.nested_index = false')
      end
    end
  end

  describe 'version' do
    it 'prints the version' do
      expect {
        described_class.start(['version'])
      }.to output(Parklife::VERSION + "\n").to_stdout
    end
  end

  describe 'config' do
    before do
      File.write('Parkfile', <<~RUBY)
        Parklife.application.configure do |config|
          config.app = Proc.new { [200, {}, ['ok']] }
        end
      RUBY
    end

    it 'prints the config' do
      expect {
        described_class.start(['config'])
      }.to output(including('app', 'base', 'build_dir')).to_stdout
    end

    it 'shows parklife-rails as enabled when Parklife::Rails is defined' do
      stub_const('Parklife::Rails', Module.new)
      expect {
        described_class.start(['config'])
      }.to output(including('enabled')).to_stdout
    end

    it 'shows parklife-sinatra as enabled when Parklife::Sinatra is defined' do
      stub_const('Parklife::Sinatra', Module.new)
      expect {
        described_class.start(['config'])
      }.to output(including('enabled')).to_stdout
    end
  end

  describe 'routes' do
    before do
      File.write('Parkfile', <<~RUBY)
        Parklife.application.configure do |config|
          config.app = Proc.new { [200, {}, ['ok']] }
        end

        Parklife.application.routes do
          root crawl: true
        end
      RUBY
    end

    it 'prints the routes' do
      expect {
        described_class.start(['routes'])
      }.to output(including('/', 'crawl=true')).to_stdout
    end

    it 'prints routes without crawl flag' do
      File.write('Parkfile', <<~RUBY)
        Parklife.application.configure do |config|
          config.app = Proc.new { [200, {}, ['ok']] }
        end

        Parklife.application.routes do
          get '/about'
        end
      RUBY

      expect {
        described_class.start(['routes'])
      }.to output(including('/about')).to_stdout
    end
  end

  describe 'get' do
    before do
      File.write('Parkfile', <<~RUBY)
        Parklife.application.configure do |config|
          config.app = Proc.new { [200, {}, ['hello']] }
        end
      RUBY
    end

    it 'prints the response body' do
      expect {
        described_class.start(['get', '/foo'])
      }.to output("hello\n").to_stdout
    end
  end

  describe 'build' do
    before do
      File.write('Parkfile', <<~RUBY)
        Parklife.application.configure do |config|
          config.app = Proc.new { [200, {}, ['ok']] }
        end

        Parklife.application.routes do
          root crawl: true
        end
      RUBY
    end

    context 'with --skip-build-meta' do
      it 'skips writing build metadata' do
        expect {
          described_class.start(['build', '--skip-build-meta'])
        }.to output(a_string_matching(/\S/)).to_stdout

        expect(File.exist?('build/index.html')).to be(true)
        expect(File.exist?('build/.parklife/build.yml')).to be(false)
      end
    end

    context 'with --cache-dir' do
      it 'uses the cache dir' do
        expect {
          described_class.start(['build', '--cache-dir', '/tmp/parklife-cache'])
        }.to output(a_string_matching(/\S/)).to_stdout

        expect(File.exist?('build/index.html')).to be(true)
      end
    end

    context 'with --no-colour' do
      it 'builds without colour' do
        expect {
          described_class.start(['build', '--no-colour'])
        }.to output(a_string_matching(/\S/)).to_stdout

        expect(File.exist?('build/index.html')).to be(true)
      end
    end

    context 'with --reporter' do
      it 'uses the given reporter' do
        expect {
          described_class.start(['build', '--reporter', 'log'])
        }.to output(including('/')).to_stdout

        expect(File.exist?('build/index.html')).to be(true)
      end
    end

    context 'with --base' do
      it 'uses the given base URL' do
        expect {
          described_class.start(['config', '--base', 'https://example.org'])
        }.to output(including('https://example.org')).to_stdout
      end
    end
  end
end
