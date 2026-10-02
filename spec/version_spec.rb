require 'spec_helper'

RSpec.describe 'IcalFilterProxy::VERSION' do
  let(:changelog) { File.read(File.expand_path('../CHANGELOG.md', __dir__)) }

  it 'matches the latest release in CHANGELOG.md' do
    latest = changelog[/^## \[(\d+\.\d+\.\d+)\]/, 1]
    expect(IcalFilterProxy::VERSION).to eq(latest)
  end

  it 'has a compare link for the latest release' do
    expect(changelog).to include("[#{IcalFilterProxy::VERSION}]: https://github.com/bdredz/ical-filter-proxy/compare/")
  end
end
