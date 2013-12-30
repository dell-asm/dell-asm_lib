-------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------

Usage Scenario in Puppet Provider:
---------------------------------
 # Set the power state.
  def power_state=(value)
    Puppet.debug "Setting the power state of the virtual machine."
    begin
      # Perform operations if desired power_state=:poweredOff
      if value == :poweredOff
        if ((vm.guest.toolsStatus != 'toolsNotInstalled') or (vm.guest.toolsStatus != 'toolsNotRunning')) and resource[:graceful_shutdown] == :true
          vm.ShutdownGuest
          # Since vm.ShutdownGuest doesn't return a task we need to poll the VM powerstate before returning.
          attempt = 5  # let's check 5 times (1 min 15 seconds) before we forcibly poweroff the VM.
          while power_state != "poweredOff" and attempt > 0
            sleep 15
            attempt -= 1
          end
          vm.PowerOffVM_Task.wait_for_completion if power_state != "poweredOff"
        else
          vm.PowerOffVM_Task.wait_for_completion
        end
        # Perform operations if desired power_state=:poweredOn
      elsif value == :poweredOn
        vm.PowerOnVM_Task.wait_for_completion
        # Perform operations if desired power_state=:suspend
      elsif value == :suspended
        if power_state == "poweredOn"
          vm.SuspendVM_Task.wait_for_completion
        else
          raise AsmException.new("ASM002", nil, [vm.name])
        end
        # Perform operations if desired power_state=:reset
      elsif value == :reset
        if power_state !~ /poweredOff|suspended/i
          vm.ResetVM_Task.wait_for_completion
        else
          raise AsmException.new("ASM003", nil, [vm.name])
        end
      end
    rescue AsmException => ae
      ae.log_message
    rescue Exception => e
      AsmException.new("ASM001", e).log_message
    end
  end
  
-------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------

Usage Scenario in Puppet Type:
-----------------------------

newparam(:name, :namevar => true) do
    desc "The virtual machine name."
    validate do |value|
      if value.strip.length == 0
        raise AsmException.new("ASM004").message
      end
    end
  end
