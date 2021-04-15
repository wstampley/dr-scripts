require 'minitest/autorun'
load 'test/test_harness.rb'

include Harness

class TestPerceiveHealth < Minitest::Test
  def setup
    $server_buffer.clear
    $history.clear
  end

  def teardown
    @test.join if @test
  end

  def parse_perceived_health(messages, target, assertions = [])
    $server_buffer = messages.dup
    $history = $server_buffer.dup
    @test = run_script_with_proc(['common', 'common-healing-data', 'common-healing'], proc do
      perceived_health = DRCH.parse_perceived_health(target)
      assertions = [assertions] unless assertions.is_a?(Array)
      assertions.each { |assertion| assertion.call(perceived_health) }
    end)
  end

  def test_parse_perceived_health_other_wounds_and_parasites
    messages = [
      'Arnas\'s injuries include...',
      'Wounds to the NECK:',
      'Fresh External:  light scratches -- insignificant (1/13)',
      'Fresh Internal:  slightly tender -- insignificant (1/13)',
      'Wounds to the RIGHT ARM:',
      'Fresh External:  cuts and bruises about the right arm -- more than minor (4/13)',
      'Fresh Internal:  minor swelling and bruising around the right arm -- more than minor (4/13)',
      'Wounds to the LEFT ARM:',
      'Fresh Internal:  minor swelling and bruising around the left arm -- more than minor (4/13)',
      'Wounds to the RIGHT LEG:',
      'Fresh External:  light scratches -- negligible (2/13)',
      'Fresh Internal:  slightly tender -- negligible (2/13)',
      'You also sense...',
      '... a small red blood mite on his right leg.',
      'Arnas is suffering from an insignificant loss of vitality (0%).'
    ]
    parse_perceived_health(messages, 'Arnas', [
      #proc { |perceived_health| print perceived_health },
      proc { |perceived_health| assert_equal(false, perceived_health['poisoned'], 'Person should have not been poisoned and is')},
      proc { |perceived_health| assert_equal(3, perceived_health['wounds'].count, 'Person has wrong number of wounded locations') }
    ])
  end

  def test_parse_perceived_health_other_poison_no_wounds
    messages = [
      'Caprianna\'s injuries include...',
      ' ... no injuries to speak of.',
      'She has a seriously poisoned right arm.',
      'Caprianna has normal vitality.'
    ]
    parse_perceived_health(messages, 'Caprianna', [
      #proc { |perceived_health| print perceived_health },
      proc { |perceived_health| assert_equal(true, perceived_health['poisoned'], 'Person should have been poisoned and is not')},
      proc { |perceived_health| assert_equal(0, perceived_health['wounds'].count, 'Person has wrong number of wounded locations') }
    ])
  end

  def test_parse_perceived_health_other_poison_and_wounds
    messages = [
      'Gorloke\'s injuries include...',
      'Wounds to the LEFT ARM:',
      '  Fresh Internal:  minor swelling and bruising around the left arm -- more than minor (4/13)',
      'Wounds to the RIGHT HAND:',
      '  Fresh External:  light scratches -- negligible (2/13)',
      '  Fresh Internal:  slightly tender -- negligible (2/13)',
      'Wounds to the LEFT HAND:',
      '  Fresh External:  light scratches -- insignificant (1/13)',
      '  Fresh Internal:  slightly tender -- insignificant (1/13)',
      'Wounds to the CHEST:',
      '  Fresh External:  light scratches -- negligible (2/13)',
      '  Fresh Internal:  slightly tender -- negligible (2/13)',
      'Wounds to the ABDOMEN:',
      '  Fresh External:  cuts and bruises about the abdomen -- more than minor (4/13)',
      '  Fresh Internal:  minor swelling and bruising in the abdomen -- more than minor (4/13)',
      'Wounds to the LEFT EYE:',
      '  Fresh External:  light scratches -- negligible (2/13)',
      '  Fresh Internal:  slightly tender -- negligible (2/13)',
      'He has a dangerously poisoned abdomen.',
      'Gorloke has normal vitality.'
    ]
    parse_perceived_health(messages, 'Gorloke', [
      #proc { |perceived_health| print perceived_health },
      proc { |perceived_health| assert_equal(true, perceived_health['poisoned'], 'Person should have been poisoned and is not')},
      proc { |perceived_health| assert_equal(3, perceived_health['wounds'].count, 'Person has wrong number of wounded locations') }
    ])
  end

  def test_parse_perceived_health_self_poison_and_wounds
    messages = [
      'Your injuries include...',
      'Wounds to the NECK:',
      '  Fresh External:  light scratches -- insignificant (1/13)',
      '  Scars External:  slight discoloration -- insignificant (1/13)',
      '  Fresh Internal:  slightly tender -- insignificant (1/13)',
      '  Scars Internal:  minor internal scarring -- insignificant (1/13)',
      'Wounds to the RIGHT ARM:',
      '  Fresh External:  light scratches -- negligible (2/13)',
      '  Scars External:  slight discoloration -- negligible (2/13)',
      '  Fresh Internal:  slightly tender -- negligible (2/13)',
      '  Scars Internal:  minor internal scarring -- negligible (2/13)',
      'Wounds to the LEFT ARM:',
      '  Fresh External:  light scratches -- negligible (2/13)',
      '  Scars External:  slight discoloration -- negligible (2/13)',
      '  Fresh Internal:  slightly tender -- negligible (2/13)',
      '  Scars Internal:  minor internal scarring -- negligible (2/13)',
      'Wounds to the RIGHT LEG:',
      '  Fresh External:  light scratches -- insignificant (1/13)',
      '  Scars External:  slight discoloration -- insignificant (1/13)',
      '  Fresh Internal:  slightly tender -- insignificant (1/13)',
      '  Scars Internal:  minor internal scarring -- insignificant (1/13)',
      'Wounds to the LEFT LEG:',
      '  Fresh External:  light scratches -- insignificant (1/13)',
      '  Scars External:  slight discoloration -- insignificant (1/13)',
      '  Fresh Internal:  slightly tender -- insignificant (1/13)',
      '  Scars Internal:  minor internal scarring -- insignificant (1/13)',
      'Wounds to the CHEST:',
      '  Scars Internal:  an occasional twitching in the chest area -- more than minor (4/13)',
      'Wounds to the ABDOMEN:',
      '  Scars External:  minor scarring along the abdomen -- more than minor (4/13)',
      '  Scars Internal:  an occasional twitching in the abdomen -- more than minor (4/13)',
      'You have a dangerously poisoned left leg.',
      'You have normal vitality.',
      'You are unusually full of extra energy.'
    ]
    parse_perceived_health(messages, nil, [
      #proc { |perceived_health| print perceived_health },
      proc { |perceived_health| assert_equal(true, perceived_health['poisoned'], 'Person should have been poisoned and is not')},
      proc { |perceived_health| assert_equal(3, perceived_health['wounds'].count, 'Person has wrong number of wounded locations') }
    ])
  end

  def test_parse_perceived_health_other_nothing_wrong
    messages = [
      'Brisby\'s injuries include...',
      '... no injuries to speak of.',
      'Brisby has normal vitality.'
    ]
    parse_perceived_health(messages, 'Brisby', [
      #proc { |perceived_health| print perceived_health },
      proc { |perceived_health| assert_equal(false, perceived_health['poisoned'], 'Person should have not been poisoned and is')},
      proc { |perceived_health| assert_equal(0, perceived_health['wounds'].count, 'Person has wrong number of wounded locations') }
    ])
  end

end
