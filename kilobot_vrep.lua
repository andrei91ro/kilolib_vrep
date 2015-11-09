------------------------------------------------------------------------------ 
-- Following few lines automatically added by V-REP to guarantee compatibility 
-- with V-REP 3.1.3 and earlier: 
colorCorrectionFunction=function(_aShapeHandle_) 
	local version=simGetIntegerParameter(sim_intparam_program_version) 
	local revision=simGetIntegerParameter(sim_intparam_program_revision) 
	if (version<30104)and(revision<3) then 
		return _aShapeHandle_ 
	end 
	return '@backCompatibility1:'.._aShapeHandle_ 
end 
------------------------------------------------------------------------------ 
 
 
------------------------------------------------------------------------------ 
-- Following few lines automatically added by V-REP to guarantee compatibility 
-- with V-REP 3.1.3 and later: 
if (sim_call_type==sim_childscriptcall_initialization) then 
	simSetScriptAttribute(sim_handle_self,sim_childscriptattribute_automaticcascadingcalls,false) 
end 
if (sim_call_type==sim_childscriptcall_cleanup) then 
 
end 
if (sim_call_type==sim_childscriptcall_sensing) then 
	simHandleChildScripts(sim_call_type) 
end 
if (sim_call_type==sim_childscriptcall_actuation) then 
	if not firstTimeHere93846738 then 
		firstTimeHere93846738=0 
	end 
	simSetScriptAttribute(sim_handle_self,sim_scriptattribute_executioncount,firstTimeHere93846738) 
	firstTimeHere93846738=firstTimeHere93846738+1 
 
------------------------------------------------------------------------------ 
 
 
-- Kilobot Model
		-- K-Team S.A. --initial version
	    -- 2013.06.24
		
		-- Andrei G. Florea --curent kilolib (kilobotics.com) adapted version
		-- 09 November 2015
		
		-- Add your own program in function loop() , after the comment "user program code goes below"
	
	if (simGetScriptExecutionCount()==0) then 
	
		-- Check if we have a controller in the scene:
		i=0
		while true do
			h=simGetObjects(i,sim_handle_all)
			if h==-1 then break end
			if simGetObjectCustomData(h,4568)=='kilobotcontroller' then
				foundCtrller=true
				break
			end
			i=i+1
		end
		if not foundCtrller then
			simDisplayDialog('Error',"The KiloBot could not find a controller.&&nMake sure to have exactly one 'Kilobot_Controller' model in the scene.",sim_dlgstyle_ok,false,nil,{0.8,0,0,0,0,0},{0.5,0,0,1,1,1})
		end
	
	
		-- save some handles
		KilobotHandle=simGetObjectAssociatedWithScript(sim_handle_self) 
	
		LeftMotorHandle=simGetObjectHandle('Kilobot_Revolute_jointLeftLeg')
		RightMotorHandle=simGetObjectHandle('Kilobot_Revolute_jointRightLeg')
	
		MsgSensorsHandle=simGetObjectHandle('Kilobot_MsgSensor')
		fullname=simGetNameSuffix(name)
	
		sensorHandle=simGetObjectHandle("Kilobot_Proximity_sensor")
		BaseHandle=simGetObjectHandle("BatHold")
	
		visionHandle=simGetObjectHandle("Vision_sensor")
		--BatGraphHandle=simGetObjectHandle("BatGraph") -- should be uncommented only for one robot
	
		half_diam=0.0165 -- half_diameter of the robot base
		
		RATIO_MOTOR = 10/255 -- ratio for getting 100% = 1cm/s or 45deg/s
	
		-- 4 constants that are calibration values used with the motors
		kilo_turn_right     = 200 -- value for cw motor to turn the robot cw in place (note: ccw motor should be off)
		kilo_turn_left    = 200 -- value for ccw motor to turn the robot ccw in place (note: cw motor should be off) 
		kilo_straight_right  = 200 -- value for the cw motor to move the robot in the forward direction
		kilo_straight_left = 200 -- value for the ccw motor to move the robot in the forward direction 

		DELAY_BLINK = 100 --ms
		blink_in_progress = 0
		timexp_blink = 0

		-- enum directions
		DIR_STOP = 0
		DIR_STRAIGHT = 1
		DIR_LEFT = 2
		DIR_RIGHT = 3

		--direction global vars
		direction = DIR_STOP
		direction_prev = DIR_STOP

	    -- for battery management
		battery_init = 8000000  -- battery initial charged value
		battery =  battery_init	-- battery simulator (~5h with 2 motors and 3 colors at 1 level)
		factMoving = 100		-- factor for discharging during moving
		moving = 0				-- for battery discharging	1: one motor, 2: 2 motors, 0: not moving
	    factCPU = 10			-- factor for discharging during cpu
		cpu=1					-- cpu state: sleep = 0, active = 1
		factLighting = 40		-- factor for discharging during lighting
		lighting=0				-- for battery managing
		bat_charge_status=0		-- battery charge status 0= no, 1, yes	
		
		charge_rate=400 		-- charge rate
		charge_max= battery_init-- battery_init*99.9/100 -- end of charge detection
	
		-------------------------------------------------------------------------------------------------------------------------------------------
		-- You should put your inital variable you would like to reset inside this function for your program.
		-- It is called when the reset button of the controller is pushed.
		reset_substate	= 0
	
		function setup()
			robot_id = math.random(0, 255) -- reset robot id
			-- below are variable to be reset for demo:
			substate1=0
			KiloState = 0
			KiloCounter = 0
			State = 0
			other_robots_id = {}
		end	
	
		
		-------------------------------------------------------------------------------------------------------------------------------------------
	
		-- for demo
		-- variables
	    substate1=0
		KiloState = 0
		KiloCounter = 0
		State = 0
		other_robots_id = {}	
		-- constants
	    SLAVE 	= 1
		MASTER	= 2
		INIT	=	0
		WAIT	=	1
		PGMCODE	=	77
		
	
		-------------------------------------------------------------------------------------------------------------------------------------------
		-- Functions similar to C API
		-------------------------------------------------------------------------------------------------------------------------------------------	
		
		function loop()
		--/////////////////////////////////////////////////////////////////////////////////////
		--//user program code goes below.  this code needs to exit in a resonable amount of time
		--//so the special message controller can also run
		--/////////////////////////////////////////////////////////////////////////////////////
	
		--/////////////////////////////////////////////////////////////////////////////////////
		--//
		--//  In the example below, the robot moves and display its distance 
		--//  to other robots with its color led.
		--//  
		--////////////////////////////////////////////////////////////////////////////////////
	
			simAddStatusbarMessage(simGetScriptName(sim_handle_self).." ambient light:"..get_ambient_light())
	
			-- Set speed
			-- set_motor(kilo_turn_right,0)
			--set_motor(kilo_straight_right,kilo_straight_left)
			set_motion(DIR_STRAIGHT)

			-- send message
			-- message_out(2,3,4)
	
	
			-- receive message and process it
			--get_message()
			if (message_rx[6]==1) then
				-- process your message
			end
	
			-- get distance to nearest obsctacle
			result,distance,detectedPoint,detectedObjectHandle,detectedSurfaceNormalVector=simReadProximitySensor(sensorHandle)
	
			if (distance ~= nil)  then 
				distance= distance + half_diam
				nameSuffix,kname=simGetNameSuffix(simGetObjectName(detectedObjectHandle))
				-- if the obstacle is another robot, light up the robot	
				if ((kname== "BatHold") or (kname== "Base")) then
				  	if(distance < 0.033) then
						set_color(3,3,3) --turn RGB LED White
					elseif(distance < 0.040) then
						set_color(3,0,0) --turn RGB LED Red
					elseif(distance < 0.050) then
					  set_color(3,3,0) --turn RGB LED Orange
					elseif(distance < 0.060) then
					  set_color(0,3,0) --turn RGB LED Green
					elseif(distance < 0.070) then			
					  set_color(0,3,1) --turn RGB LED Turquoise
					elseif(distance < 0.080) then
						set_color(0,0,3) --turn RGB LED Blue
					elseif(distance < 0.090) then
						set_color(3,0,3) --turn RGB LED Violet					
					else
						set_color(0,0,0)	 
					end 	
				end
			else
				set_color(0,0,0)
			end

			blink(0, 1, 0)
		--////////////////////////////////////////////////////////////////////////////////////
		--//END OF USER CODE
		--////////////////////////////////////////////////////////////////////////////////////
		end
		
		-------------------------------------------------------------------------------------------------------------------------------------------
		
		-- Set direction of motion (DIR_STOP, DIR_STRAIGHT, DIR_LEFT, DIR_RIGHT)
		function set_motion(dir_new)
			if (dir_new == DIR_STOP) then
				set_motor(0, 0)

			elseif (dir_new == DIR_STRAIGHT) then
				set_motor(kilo_straight_right, kilo_straight_left)

			elseif (dir_new == DIR_LEFT) then
				set_motor(0, kilo_turn_left)

			elseif (dir_new == DIR_RIGHT) then
				set_motor(kilo_turn_right, 0)
			end


			direction_prev = direction
			direction = dir_new
		end

		function blink(r, g, b)
			blink_in_progress = 1
			simAddStatusbarMessage("<-- time = ".. simGetSimulationTime());
			timexp_blink = simGetSimulationTime() + DELAY_BLINK / 1000.0
			simAddStatusbarMessage("-- timexp_blink = ".. timexp_blink);
			set_color(r, g, b)
		end

		-- Set motor speed PWM values for motors between 0 (off) and 255 (full on, ~ 1cm/s) for cw_motor and ccw_motor 
		function set_motor (cw_motor,ccw_motor)
		-- Set speed
			simSetJointTargetVelocity(RightMotorHandle,ccw_motor*RATIO_MOTOR)
			simSetJointTargetVelocity(LeftMotorHandle,cw_motor*RATIO_MOTOR)
	
			-- for battery managing
			if ((cw_motor == 0) and (ccw_motor==0)) then
				moving=0
			elseif ((cw_motor == 0) or (ccw_motor==0)) then
			  moving=1	
			else
			-- both moving
			  moving=2
			end
	
		end

		-- Set LED color, values can be from 0(off)-3(brightest) 
		function set_color(r,g,b)
			simSetShapeColor(colorCorrectionFunction(BaseHandle),"BODY",0,{r*0.6/3.0+0.1, g*0.6/3.0+0.1, b*0.6/3.0+0.1})
			lighting=r+g+b
		end
	
		-- Print integer over StatusbarMessage (serial port for real robot) - be careful can effect timing! 
		function kprinti(int)
			simAddStatusbarMessage(int)
		end
	
		-- Print string up to 10 characters - be careful, can effect timing! 
		function  kprints(string)
			simAddStatusbarMessage(string)
		end
	
		-- Set message values to be sent over IR, 3 bytes
		-- tx0,tx1,tx2 (tx2 lsb must not be used)
		tx0=0
		tx1=0
		tx2=0
		function message_out(_tx0,_tx1,_tx2)
		  tx0=_tx0
		  tx1=_tx1
		  tx2=_tx2	
		end
	
		-- received message
		message_rx = {0,0,0,0,0,0};
		enable_tx = 0 -- to turn on/off the transmitter
		senderID = nil
	
		-- Take oldest message off of rx buffer message. It is only new if message_rx[5]==1
	    -- If so, message is in message_rx[0] and message_rx[1] 
	    -- distance to transmitting robot (in mm) is in message_rx[3].
		function get_message()		
			if (data ~= nil) then
				udata=simUnpackInts(data)
				message_rx[1]=udata[1]
				message_rx[2]=udata[2]
				message_rx[3]=udata[3]
				--simAddStatusbarMessage(simGetScriptName(sim_handle_self).." "..message_rx[1].." "..message_rx[2].." "..message_rx[3])
				
				result,distance,detectedPoint,detectedObjectHandle,detectedSurfaceNormalVector=simCheckProximitySensor(sensorHandle,senderHandle)
				
				if (result == 1) then
					
					message_rx[4]=(distance+half_diam)*1000  -- distance in mm + 1/2diameter of robot
	
					message_rx[6]=1	-- message receveid
	
				else
					message_rx[6]=0 -- no message receveid
				end			
	
			else
				message_rx[6]=0 -- no message receveid
			end
	
		end
		
		special_mode = 1
		run_program = 0
		special_mode_message = 3
	
		function receive_data()
			-- receive latest message and process it
			
			data,senderID,dataHeader,dataName=simReceiveData(0,"Message",MsgSensorsHandle)
			
			if (data ~= nil) then
				senderHandle= simGetObjectAssociatedWithScript(senderID)
				udata=simUnpackInts(data)
				message_rx[1]=udata[1]
				message_rx[2]=udata[2]
				message_rx[3]=udata[3]
	
				--simAddStatusbarMessage(simGetScriptName(sim_handle_self).." received:"..message_rx[1]..message_rx[2]..message_rx[3].." from "..simGetScriptName(senderID))
				--simAddStatusbarMessage(simGetScriptName(sim_handle_self).." received from "..simGetScriptName(senderID))
				-- special message
				if (message_rx[3] == 0x1) then
					special_mode_message=message_rx[2]
					special_mode = 1
	
					--if (special_mode_message == 6	) then
					--	simAddStatusbarMessage(simGetScriptName(sim_handle_self).." received 'Run'") 
					--elseif (special_mode_message == 4	) then
					--	simAddStatusbarMessage(simGetScriptName(sim_handle_self).." received 'Pause'") 
					--elseif (special_mode_message == 5	) then
					--	simAddStatusbarMessage(simGetScriptName(sim_handle_self).." received 'Disp Bat'") 
					--elseif (special_mode_message == 7	) then
					--	simAddStatusbarMessage(simGetScriptName(sim_handle_self).." received 'Charge'") 
					--end
	
				end
			else	
				--simAddStatusbarMessage(simGetScriptName(sim_handle_self).." no received data")
			end
		end
	
		irstart=simGetSimulationTime()
	
		function send_data() -- send data from ir every 0.2s, at a max distance of 7cm
			newir=simGetSimulationTime()
			--simAddStatusbarMessage(simGetScriptName(sim_handle_self).." enable_tx:"..enable_tx.."  irstart:"..irstart.."  newir:"..newir)
			if ((enable_tx==1) and (newir-irstart>0.2)) then
				simSendData(sim_handle_all,0,"Message",simPackInts({tx0,tx1,tx2}),MsgSensorsHandle,0.07,3.1415,3.1415*2,0.8)
				--simAddStatusbarMessage(simGetScriptName(sim_handle_self).." sent a mesage")
				irstart=newir
	        end 
			
		end
	
		-- Measure battery voltage, returns voltage in .01 volt units
		-- for example if 394 is returned, then the voltage is 3.94 volts 
		function measure_voltage()
			return battery*420/battery_init
		end
	
		-- Measure if battery is charging, returns 0 if no, 1 if yes 
		function measure_charge_status()
			return bat_charge_status
		end
	
		substate=0 -- sub state for state machine of message
	
		-- battery management
		function update_battery()
			dt=simGetSimulationTimeStep()
			battery=battery-factLighting*lighting-factMoving*moving-factCPU*cpu
			--simSetGraphUserData(BatGraphHandle,"Battery",battery)  -- should be uncommented only for one robot
		end
	
		delay_start=simGetSimulationTime()
	
			-- wait for x milliseconds  global variable delay_start should be initialised with:  delay_start=simGetSimulationTime()
		function _delay_ms(x)
			--simWait(x/1000.0,true)
				if ((simGetSimulationTime()-delay_start)>=(x/1000.0)) then
					return 1
				end
			return 0
		end
	
	
	
	
	    -- Returns the value of ambient light
		function get_ambient_light()
			result,auxValues1,auxValues2=simReadVisionSensor(visionHandle)
			if (auxValues1) then
				
				return auxValues1[11] -- return average intensity
			else
				return -1
			end
		end
	
		-------------------------------------------------
		-- other initialisations
	
		robot_id = math.random(0, 255) -- set robot id
	
		-- get number of other robots
	
		NUMBER_OTHER_ROBOTS=0
		objIndex=0
		while (true) do
			h=simGetObjects(objIndex,sim_object_shape_type)
			if (h<0) then
				break
			end
			objIndex=objIndex+1
			--simAddStatusbarMessage("objIndex: "..objIndex)
			if ((simGetObjectCustomData(h,1834746)=="kilobot") and (KilobotHandle ~= h))then
				NUMBER_OTHER_ROBOTS=NUMBER_OTHER_ROBOTS+1
				--simAddStatusbarMessage("NUMBER_OTHER_ROBOTS: "..NUMBER_OTHER_ROBOTS)
			end
		end	
	
		--simAddStatusbarMessage("number of robots found: "..robotnb)
	
	
	end
	
	---------------------------------------------------------------------------
	---------------------------------------------------------------------------
	-- main script loop
	
	simHandleChildScripts(sim_call_type)
	
	update_battery() -- update battery value
	
	receive_data() -- received data by ir
	
	send_data() -- send data by ir
	
	--special message controller, handles controll messages like sleep and resume program
	if(special_mode==1) then
	
		run_program=0
	
		special_mode=0
		set_motor(0,0)
	
		-- modes for different values of special_mode_message	 
		--0x01 bootloader (not implemented)
		--0x02 sleep (not implemented)
		--0x03 wakeup, go to mode 0x04
		--0x04 Robot on, but does nothing active
		--0x05 display battery voltage
		--0x06 execute program code
		--0x07 battery charge
		--0x08 reset program
	
	
		if(special_mode_message==0x02) then
		  -- sleep	
			wakeup=0
			--enter_sleep();//will not return from enter_sleep() untill a special mode message 0x03 is received	
		elseif((special_mode_message==0x03)or(special_mode_message==0x04)) then
		  --wakeup / Robot on, but does nothing active
			enable_tx=0
			
			--simAddStatusbarMessage(simGetScriptName(sim_handle_self).." substate: "..substate) 
	
			-- make the led blink
			if (substate==0) then	
				set_color(3,3,0)
				substate=substate+1
				delay_start=simGetSimulationTime()
			elseif (substate==1) then
				if (_delay_ms(50)==1) then 
					substate=substate+1
				end
			elseif (substate==2) then
				set_color(0,0,0)
				substate=substate+1
				delay_start=simGetSimulationTime()
			elseif (substate==3) then
				if (_delay_ms(1300)==1) then
					substate=0
				end
			end
	
			enable_tx=1
			special_mode=1
		
		elseif(special_mode_message==0x05) then
		 -- display battery voltage
			enable_tx=0
	
			if(measure_voltage()>400) then
				set_color(0,3,0)
			elseif(measure_voltage()>390) then
				set_color(0,0,3)
			elseif(measure_voltage()>350) then
				set_color(3,3,0)
			else
				set_color(3,0,0)
			end
	
			enable_tx=1
			--simAddStatusbarMessage(simGetScriptName(sim_handle_self).." Voltage: "..measure_voltage().."  battery:"..battery)
		elseif (special_mode_message==0x06) then
			--execute program code
			enable_tx=1
			run_program=1
			substate = 0
			--simAddStatusbarMessage(simGetScriptName(sim_handle_self).." special mode Run") 
			--no code here, just allows special_mode to end 
	
		elseif (special_mode_message==0x07) then
		 --battery charge
			enable_tx=0
			--if(measure_charge_status()==1) then
			
			if (battery<charge_max) then
				if (substate==0) then	
					set_color(1,0,0)
					substate=substate+1
					delay_start=simGetSimulationTime()
				elseif (substate==1) then
					if (_delay_ms(50)==1) then 
						substate=substate+1
					end
				elseif (substate==2) then
					set_color(0,0,0)
					substate=substate+1
					delay_start=simGetSimulationTime()
				elseif (substate==3) then
					if (_delay_ms(300)==1) then
						substate=0
					end
				end
			
				battery=battery+charge_rate
			
				if (battery>battery_init) then
					battery=battery_init
				end
			end
			special_mode=1
	
	
	
			enable_tx=1
		elseif (special_mode_message==0x08) then
			
			if (reset_substate==0)	then
			--reset
			enable_tx=0
			setup()
			run_program = 0
			special_mode_message = 0x08
			reset_substate = reset_substate + 1
			-- wait some time for stopping messages
			--simAddStatusbarMessage(simGetScriptName(sim_handle_self).." start resetting") 
			delay_reset=simGetSimulationTime()
			elseif (simGetSimulationTime()-delay_reset>=1.5) then  	
				special_mode_message = 3
				reset_substate	= 0
			else
				while (simReceiveData(0,"Message",MsgSensorsHandle)) do 
					--simAddStatusbarMessage(simGetScriptName(sim_handle_self).." empty message buffer") 
				end
			end
			
			special_mode = 1
	
		end
	
	end
	
	if(run_program==1) then
		
		--simAddStatusbarMessage(simGetScriptName(sim_handle_self).." process Run") 
		if (blink_in_progress == 1) then
			if (simGetSimulationTime() >= timexp_blink) then
				simAddStatusbarMessage("--> time = ".. simGetSimulationTime());
				blink_in_progress = 0;
				set_color(0, 0, 0);
			end
		else
			loop()
		end
	
	end
	
	
	if (simGetSimulationState()==sim_simulation_advancing_lastbeforestop) then
		-- Put some restoration code here
		set_color(0,0,0)
	end
 
 
------------------------------------------------------------------------------ 
-- Following few lines automatically added by V-REP to guarantee compatibility 
-- with V-REP 3.1.3 and later: 
end 
------------------------------------------------------------------------------ 
