# frozen_string_literal: true

require 'aws-sdk-elasticloadbalancingv2'
require 'hako'
require 'hako/error'
require 'hako/scheduler'
require 'hako/schedulers/ecs_elb_v2'

module Hako
  module Schedulers
    class EcsMultipleElbV2
      # @param [String] app_id
      # @param [String] region
      # @param [Array<Hash>] elb_multiple_v2_config
      # @param [Boolean] dry_run
      def initialize(app_id, region, elb_multiple_v2_config, dry_run:)
        @region = region
        @elb_multiple_v2_config = elb_multiple_v2_config
        validate_elb_multiple_v2_config!
        @elb_v2s = @elb_multiple_v2_config.map { |elb_v2_config| EcsElbV2.new(app_id, region, elb_v2_config, dry_run: dry_run) }
      end

      # @param [Array<Aws::ECS::Types::LoadBalancer>] ecs_lbs
      # @return [nil]
      def show_status(ecs_lbs)
        ecs_lb_map = ecs_lbs.map do |ecs_lb|
          [resolve_load_balancer_name_from_target_group_arn(ecs_lb.target_group_arn), ecs_lbs]
        end.to_h

        @elb_v2s.each do |elb_v2|
          ecs_lb = ecs_lb_map[elb_v2.elb_name]
          elb_v2.show_status([ecs_lb])
        end

        nil
      end

      # @param [Fixnum] front_port
      # @return [Boolean]
      def find_or_create_load_balancer(front_port)
        @elb_v2s.map { |elb_v2| elb_v2.find_or_create_load_balancer(front_port) }.inject(false) { |result, item| result || item }
      end

      # @return [nil]
      def modify_attributes
        nil
      end

      # @return [nil]
      def destroy
        nil
      end

      # @return [Array<Hash>]
      def load_balancer_params_for_service
        @elb_v2s.flat_map(&:load_balancer_params_for_service)
      end

      private

      def validate_elb_multiple_v2_config!
        @elb_multiple_v2_config.each do |elb_v2_config|
          # load_balancer_name and target_group_name should always be able to identified to create multiple load balancers and target groups,
          # but there's no way to do that because the order of multiple_elb_v2 cannot be guaranteed
          unless elb_v2_config['load_balancer_name']
            raise Hako::Scheduler::ValidationError.new('load_balancer_name is required in multiple_elb_v2 scheduler')
          end
          unless elb_v2_config['target_group_name']
            raise Hako::Scheduler::ValidationError.new('targer_group_name is required in multiple_elb_v2 scheduler')
          end
        end
      end

      def resolve_load_balancer_name_from_target_group_arn(target_group_arn)
        target_group = elb_client.describe_target_groups(target_group_arns: [target_group_arn]).target_groups[0]
        elb_client.describe_load_balancers(load_balancer_arns: target_group.load_balancer_arns).load_balancers[0].load_balancer_name
      end

      def elb_client
        @elb_v2 ||= Aws::ElasticLoadBalancingV2::Client.new(region: @region)
      end
    end
  end
end
