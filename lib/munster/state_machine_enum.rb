# frozen_string_literal: true

# This concern adds a method called "state_enum" useful for defining an enum using
# string values along with valid state transitions. Validations will be added for the
# state transitions and a proper enum is going to be defined. For example:
#
#   state_machine_enum :state do |states|
#     states.permit_transition(:created, :approved_pending_settlement)
#     states.permit_transition(:approved_pending_settlement, :rejected)
#     states.permit_transition(:created, :rejected)
#     states.permit_transition(:approved_pending_settlement, :settled)
#   end
module Munster
  module StateMachineEnum
    extend ActiveSupport::Concern

    class StatesCollector
      attr_reader :states
      attr_reader :after_commit_hooks
      attr_reader :common_after_commit_hooks
      attr_reader :after_attribute_write_hooks
      attr_reader :common_after_write_hooks

      def initialize
        @transitions = Set.new
        @states = Set.new
        @after_commit_hooks = {}
        @common_after_commit_hooks = []
        @after_attribute_write_hooks = {}
        @common_after_write_hooks = []
      end

      def permit_transition(from, to)
        @states << from.to_s << to.to_s
        @transitions << [from.to_s, to.to_s]
      end

      def may_transition?(from, to)
        @transitions.include?([from.to_s, to.to_s])
      end

      def after_inline_transition_to(target_state, &blk)
        @after_attribute_write_hooks[target_state.to_s] ||= []
        @after_attribute_write_hooks[target_state.to_s] << blk.to_proc
      end

      def after_committed_transition_to(target_state, &blk)
        @after_commit_hooks[target_state.to_s] ||= []
        @after_commit_hooks[target_state.to_s] << blk.to_proc
      end

      def after_any_committed_transition(&blk)
        @common_after_commit_hooks << blk.to_proc
      end

      def validate(model, attribute_name)
        return unless model.persisted?

        was = model.attribute_was(attribute_name)
        is = model[attribute_name]

        unless was == is || @transitions.include?([was, is])
          model.errors.add(attribute_name, "Invalid transition from #{was} to #{is}")
        end
      end
    end

    class InvalidState < StandardError
    end

    class_methods do
      def state_machine_enum(attribute_name, **options_for_enum)
        # Collect the states
        collector = StatesCollector.new
        yield(collector).tap do
          # Define the enum using labels, with string values
          enum_map = collector.states.map(&:to_sym).zip(collector.states.to_a).to_h
          enum(attribute_name, enum_map, **options_for_enum)

          # Define validations for transitions
          validates attribute_name, presence: true
          validate { |model| collector.validate(model, attribute_name) }

          # Define inline hooks
          before_save do |model|
            _value_was, value_has_become = model.changes[attribute_name]
            next unless value_has_become
            hook_procs = collector.after_attribute_write_hooks[value_has_become].to_a + collector.common_after_write_hooks.to_a
            hook_procs.each do |hook_proc|
              hook_proc.call(model)
            end
          end

          # Define after commit hooks
          after_commit do |model|
            _value_was, value_has_become = model.previous_changes[attribute_name]
            next unless value_has_become
            hook_procs = collector.after_commit_hooks[value_has_become].to_a + collector.common_after_commit_hooks.to_a
            hook_procs.each do |hook_proc|
              hook_proc.call(model)
            end
          end

          # Define the check methods
          define_method(:"ensure_#{attribute_name}_one_of!") do |*allowed_states|
            val = self[attribute_name]
            return if Set.new(allowed_states.map(&:to_s)).include?(val)
            raise InvalidState, "#{attribute_name} must be one of #{allowed_states.inspect} but was #{val.inspect}"
          end

          define_method(:"ensure_#{attribute_name}_may_transition_to!") do |next_state|
            val = self[attribute_name]
            raise InvalidState, "#{attribute_name} already is #{val.inspect}" if next_state.to_s == val
          end

          define_method(:"#{attribute_name}_may_transition_to?") do |next_state|
            val = self[attribute_name]
            return false if val == next_state.to_s
            collector.may_transition?(val, next_state)
          end
        end
      end
    end
  end
end
