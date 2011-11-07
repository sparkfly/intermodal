module Intermodal
  module RSpec
    # All Intermodal controllers require models that belongs to an
    # account object and responds to #get. This allows the controllers
    # to fetch records authorized by the account.
    #
    # This RSpec macro tests these assumptions.
    #
    # Usage:
    #
    # class Resource < ActiveRecord::Base
    #   include Intermodal::Models::Accountability
    # end
    #
    # describe Resource do
    #   include Intermodal::RSpec::Accountability
    #
    #   concerned_with_accountability
    # end
    #
    # It works with Remarkable. It might work with Shoulda
    #
    # If you don't want to use either, you can try
    #
    # describe Resource do
    #   include Intermodal::RSpec::Accountability
    #
    #   implements_get_interface
    # end
    #
    module Accountability
      extend ActiveSupport::Concern

      module ClassMethods
        def concerned_with_accountability(&blk)
          instance_eval(&blk) if blk

          context 'when concerned with accountability' do
            let(:model) { subject.class }

            it { should belong_to :account }
            it { should validate_presence_of :account }
            it { model.should respond_to :by_account_id }
            it { model.should respond_to :by_account }

            implements_get_interface
          end
        end

        def implements_get_interface(&blk)
          describe '.get' do
            let(:model) { subject.class }
            let(:different_account) { Account.make! }

            it { model.should respond_to :get }

            context ':all' do
              let(:collection) { model.get(:all) }
              it 'should find all resources' do
                collection.should include(subject)
                collection.size.should eql(1)
              end
            end

            context 'by id' do
              it 'should find resource by id' do
                model.get(subject.id).should eql(subject)
              end

              it 'should return a writeable resource' do
                model.get(subject.id).should_not be_readonly
              end
            end

            context 'by account' do
              it 'should find resource scoped to account' do
                model.get(subject.id, :account => account).should eql(subject)
              end

              it 'should find resource scoped to account id' do
                model.get(subject.id, :account_id => account.id).should eql(subject)
              end

              it 'should find a writeable resource scoped to account id' do
                model.get(subject.id, :account_id => account.id).should_not be_readonly
              end

              it 'should not find resource scoped to a different account' do
                lambda { model.get(subject.id, :account => different_account) }.should raise_error(ActiveRecord::RecordNotFound)
              end

              it 'should not find resource scoped to a different account id ' do
                lambda { model.get(subject.id, :account_id => different_account.id) }.should raise_error(ActiveRecord::RecordNotFound)
              end
            end

            instance_eval(&blk) if blk
          end
        end # implements_get_interface
      end # ClassMethods

    end
  end
end

