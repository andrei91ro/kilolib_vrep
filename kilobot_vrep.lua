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


		-- message synopsys (follows kilobotics.com/message.h):
		-- msg = {type, data} where
		-- 		msg_type = uint8_t (MSG_TYPE_* see below)
		-- 		data = uint8_t[9] (table of 9 uint8_t)


		--special message codes (message_type_t)
		MSG_TYPE_NORMAL = 0
		MSG_TYPE_PAUSE = 4
		MSG_TYPE_VOLTAGE = 5
		MSG_TYPE_RUN = 6
		MSG_TYPE_CHARGE = 7
		MSG_TYPE_RESET = 8

		--blink auxiliaries
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
	
		reset_substate	= 0

		-------------------------------------------------------------------------------------------------------------------------------------------
		--global variables
		-------------------------------------------------------------------------------------------------------------------------------------------


		-------------------------------------------------------------------------------------------------------------------------------------------
		-- Functions similar to C API
		-------------------------------------------------------------------------------------------------------------------------------------------
		--called for each received message (of type == MSG_TYPE_NORMAL)
		-- @param msg_data (uint8_t[9] in C) : data contained in the message
		-- @param distance (uint8_t in C) : measured distance from the sender
		function message_rx(msg_data, distance)
			simAddStatusbarMessage("Message[1] = " .. msg_data[1] .. " received with distance = " .. distance)
		end

		--called to construct every sent message
		--should be restricted to a 9 unsigned int table (as is the case for real kilobots)
		--@return msg = {type, data} where
		-- 		msg_type = uint8_t (MSG_TYPE_* see synopsys)
		-- 		data = uint8_t[9] (table of 9 uint8_t)
		function message_tx()
			simAddStatusbarMessage("Message built");
			return {msg_type=MSG_TYPE_NORMAL, data={11, 22, 33, 44, 55, 66, 77, 88, 99}}
		end

		--called after each successfull message transmission
		function message_tx_success()
			simAddStatusbarMessage("Message sent");
		end

		--function called only once at simmulation start (or after clicking Reset from the controller)
		--You should put your inital variable you would like to reset inside this function for your program.
		function setup()
			-- get unique robot id from "robotID" parameter
			kilo_uid = simGetScriptSimulationParameter(sim_handle_self, "robotID", false)
			simAddStatusbarMessage(simGetScriptName(sim_handle_self) .. ": kilo_uid=" .. kilo_uid)
		end	
		
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
	
			--simAddStatusbarMessage(simGetScriptName(sim_handle_self).." ambient light:"..get_ambient_light())
	
			set_motion(DIR_STRAIGHT)
	
			if (distance ~= nil)  then 
				distance= distance + half_diam
				-- if the obstacle is another robot, light up the robot	
				if(distance < 33) then
					set_color(3,3,3) --turn RGB LED White
				elseif(distance < 40) then
					set_color(3,0,0) --turn RGB LED Red
				elseif(distance < 50) then
					set_color(3,3,0) --turn RGB LED Orange
				elseif(distance < 60) then
					set_color(0,3,0) --turn RGB LED Green
				elseif(distance < 70) then
					set_color(0,3,1) --turn RGB LED Turquoise
				elseif(distance < 80) then
					set_color(0,0,3) --turn RGB LED Blue
				elseif(distance < 90) then
					set_color(3,0,3) --turn RGB LED Violet
				else
					set_color(0,0,0)
				end
			else
				set_color(0,0,0)
			end

			--blink(0, 1, 0)
		--////////////////////////////////////////////////////////////////////////////////////
		--//END OF USER CODE
		--////////////////////////////////////////////////////////////////////////////////////
		end
		
		-------------------------------------------------------------------------------------------------------------------------------------------
		
	    -- Returns the value of ambient light
		function get_ambient_light()
			result,auxValues1,auxValues2=simReadVisionSensor(visionHandle)
			if (auxValues1) then

				return auxValues1[11] -- return average intensity
			else
				return -1
			end
		end

		-- Set direction of motion
		-- @param dir_new : new direction to go, one of (DIR_STOP, DIR_STRAIGHT, DIR_LEFT, DIR_RIGHT)
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

		--blinks LED for DELAY_BLINK interval
		-- @param r : red value (0-3)
		-- @param g : green value (0-3)
		-- @param b : blue value (0-3)
		function blink(r, g, b)
			blink_in_progress = 1
			--simAddStatusbarMessage("<-- time = ".. simGetSimulationTime());
			timexp_blink = simGetSimulationTime() + DELAY_BLINK / 1000.0
			--simAddStatusbarMessage("-- timexp_blink = ".. timexp_blink);
			set_color(r, g, b)
		end

		-- Set motor speed PWM values for motors between 0 (off) and 255 (full on, ~ 1cm/s) for cw_motor and ccw_motor 
		function set_motor(cw_motor,ccw_motor)
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

		-- Set LED color
		-- @param r : red value (0-3)
		-- @param g : green value (0-3)
		-- @param b : blue value (0-3)
		function set_color(r,g,b)
			simSetShapeColor(colorCorrectionFunction(BaseHandle),"BODY",0,{r*0.6/3.0+0.1, g*0.6/3.0+0.1, b*0.6/3.0+0.1})
			lighting=r+g+b
		end
	
		-------------------------------------------------------------------------------------------------------------------------------------------
		-- END Functions similar to C API
		-------------------------------------------------------------------------------------------------------------------------------------------
	
		enable_tx = 0 -- to turn on/off the transmitter
		senderID = nil
	
		special_mode = 1
		run_program = 0
		special_mode_message = MSG_TYPE_RESET --start the robot with a reset (to call setup() only once during start-up)
	
		function receive_data()
			-- receive latest message and process it
			
			data,senderID,dataHeader,dataName=simReceiveData(0,"Message",MsgSensorsHandle)
			
			if (data ~= nil) then
				senderHandle= simGetObjectAssociatedWithScript(senderID)
				udata=simUnpackInts(data)
				
				--reconstruct message structure
				message = {msg_type = udata[1], 
							data = {udata[2], udata[3], udata[4], udata[5], udata[6], udata[7], udata[8], udata[9], udata[10]}}

				--simAddStatusbarMessage("message[msg_type] = " .. message["msg_type"]);

				-- special message
				if (message["msg_type"] > MSG_TYPE_NORMAL) then
					special_mode_message = message["msg_type"]
					special_mode = 1
	
				else
					--normal message processing

					result, distance, detectedPoint = simCheckProximitySensor(sensorHandle,senderHandle)
					
					-- if the distance was extracted corectly
					if (result == 1) then
						distance = (distance + half_diam) * 1000  -- distance in mm + 1/2diameter of robot
						-- send the message contents to user processing with distance
						message_rx(message["data"], distance)
					end
				end
			else	
				--simAddStatusbarMessage(simGetScriptName(sim_handle_self).." no received data")
			end
		end
	
		irstart=simGetSimulationTime()
	
		function send_data() -- send data from ir every 0.2s, at a max distance of 7cm (ONLY if kilobot is in normal running state)
			newir=simGetSimulationTime()
			--simAddStatusbarMessage(simGetScriptName(sim_handle_self).." enable_tx:"..enable_tx.."  irstart:"..irstart.."  newir:"..newir)
			if ((enable_tx==1) and (newir-irstart>0.2) and (run_program == 1)) then
				local new_msg = message_tx() --the user function is resposible for composing the message
				--serialize (msg_type, data[1], data[2], ... data[9]) and send message
				simSendData(sim_handle_all,0,"Message",
					simPackInts({new_msg["msg_type"], new_msg["data"][1], new_msg["data"][2], new_msg["data"][3], new_msg["data"][4], new_msg["data"][5],
						new_msg["data"][6], new_msg["data"][7], new_msg["data"][8], new_msg["data"][9]}),
					MsgSensorsHandle,0.07,3.1415,3.1415*2,0.8)

				--message transmission ok => notify the user
				message_tx_success()

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
	
		-------------------------------------------------
		-- other initialisations
	
		--kilo_uid = math.random(0, 255) -- set robot id
	
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
		elseif((special_mode_message==0x03)or(special_mode_message==MSG_TYPE_PAUSE)) then
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
		
		elseif(special_mode_message==MSG_TYPE_VOLTAGE) then
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
		elseif (special_mode_message==MSG_TYPE_RUN) then
			--execute program code
			enable_tx=1
			run_program=1
			substate = 0
			--simAddStatusbarMessage(simGetScriptName(sim_handle_self).." special mode Run") 
			--no code here, just allows special_mode to end 
	
		elseif (special_mode_message==MSG_TYPE_CHARGE) then
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
		elseif (special_mode_message==MSG_TYPE_RESET) then
			
			if (reset_substate==0)	then
			--reset
			enable_tx=0
			setup()
			run_program = 0
			special_mode_message = MSG_TYPE_RESET
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
