{
  scheduler: {
    type: 'ecs',
    region: 'ap-northeast-1',
    cluster: 'eagletmt',
    desired_count: 1,
    role: 'ECSServiceRole',
    multiple_elb_v2: [
      {
        load_balancer_name: 'public',
        target_group_name: 'public',
        vpc_id: 'vpc-11111111',
        health_check_path: '/site/sha',
        listeners: [
          {
            port: 80,
            protocol: 'HTTP',
          },
          {
            port: 443,
            protocol: 'HTTPS',
            ssl_policy: 'ELBSecurityPolicy-2016-08',
            certificate_arn: 'arn:aws:acm:ap-northeast-1:012345678901:certificate/01234567-89ab-cdef-0123-456789abcdef',
          },
        ],
        subnets: [
          'subnet-11111111',
          'subnet-22222222',
        ],
        security_groups: [
          'sg-11111111',
        ],
      },
      {
        load_balancer_name: 'internal',
        target_group_name: 'internal',
        vpc_id: 'vpc-22222222',
        health_check_path: '/site/sha',
        listeners: [
          {
            port: 80,
            protocol: 'HTTP',
          },
          {
            port: 443,
            protocol: 'HTTPS',
            ssl_policy: 'ELBSecurityPolicy-2016-08',
            certificate_arn: 'arn:aws:acm:ap-northeast-1:012345678901:certificate/01234567-89ab-cdef-0123-456789abcdef',
          },
        ],
        subnets: [
          'subnet-33333333',
          'subnet-44444444',
        ],
        security_groups: [
          'sg-22222222',
        ],
      },
    ],
  },
  app: {
    image: 'busybox',
    cpu: 32,
    memory: 64,
  },
}
