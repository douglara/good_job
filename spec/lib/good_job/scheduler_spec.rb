require 'rails_helper'

RSpec.describe GoodJob::Scheduler do
  let(:performer) { instance_double(GoodJob::Performer, next: nil, name: '') }

  around do |example|
    expect { example.run }.to output.to_stdout # rubocop:disable RSpec/ExpectInHook
  end

  describe '.instances' do
    it 'contains all registered instances' do
      scheduler = nil
      expect do
        scheduler = described_class.new(performer)
      end.to change { described_class.instances.size }.by(1)

      expect(described_class.instances).to include scheduler
    end
  end

  describe '#shutdown' do
    it 'shuts down the theadpools' do
      scheduler = described_class.new(performer)

      scheduler.shutdown

      expect(scheduler.instance_variable_get(:@timer).running?).to be false
      expect(scheduler.instance_variable_get(:@pool).running?).to be false
    end
  end

  describe '#restart' do
    it 'restarts the threadpools' do
      scheduler = described_class.new(performer)
      scheduler.shutdown

      scheduler.restart

      expect(scheduler.instance_variable_get(:@timer).running?).to be true
      expect(scheduler.instance_variable_get(:@pool).running?).to be true
    end
  end
end