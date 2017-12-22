require 'test_helper'

class ThreadSafetyTest < ActionController::TestCase
  test "be thread safe when using #set_paper_trail_whodunnit" do
    blocked = true

    slow_thread = Thread.new do
      controller = TestController.new
      controller.send :set_paper_trail_whodunnit
      begin
        sleep 0.001
      end while blocked
      PaperTrail.whodunnit
    end

    fast_thread = Thread.new do
      controller = TestController.new
      controller.send :set_paper_trail_whodunnit
      who = PaperTrail.whodunnit
      blocked = false
      who
    end

    assert_not_equal slow_thread.value, fast_thread.value
  end

  test "be thread safe when using #without_versioning" do
    enabled = nil

    slow_thread = Thread.new do
      Widget.new.without_versioning do
        sleep(0.01)
        enabled = Widget.paper_trail_enabled_for_model?
        sleep(0.01)
      end
      enabled
    end

    fast_thread = Thread.new do
      sleep(0.005)
      Widget.paper_trail_enabled_for_model?
    end

    assert_not_equal slow_thread.value, fast_thread.value
    assert Widget.paper_trail_enabled_for_model?
    assert PaperTrail.enabled_for_model?(Widget)
  end
end
