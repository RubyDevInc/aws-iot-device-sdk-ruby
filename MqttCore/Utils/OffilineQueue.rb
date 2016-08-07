module MqttCore
  module Utils

    class OfflineQueue < Queue
      
      attr_accessor :drop_behavior
      attr_accessor :queue_size

      DROP_OLDEST = 0
      DROP_NEWEST = 1
      
      def initialize(queue_size=10, drop_behavior=0)
        unless size.is_a?(Integer) and drop_behavior.is_a?(Integer)
          @queue_size = queue_size
          @drop_behavior = drop_behavior
        else
          raise "OfflineQueue error: drop_behavior and queue_size should be Interger type}"
        end
      end

      def need_drop
        ret = false
        if self.lenght >= self.queue_size
          ret = true
          puts "OfflineQueue warning: OfflineQueue is full" 
        end
        ret
      end
      
      def push(pkg)
        unless need_drop
          self.push(pkg)
        elsif self.drop_behavior == DROP_OLDEST
          self.pop
          self.push(pkg)
        end
      end
    end
  end
end
