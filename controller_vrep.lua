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
 
 
-- Kilobot Controller for Kilobot Model
	-- K-Team S.A.
	-- 2013.06.24  

	-- Andrei G. Florea --curent kilolib (kilobotics.com) adapted version
	-- 09 November 2015
	
	
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

	if (simGetScriptExecutionCount()==0) then
		uiCtrl=simGetUIHandle("Kilobot_Controller")
		MsgSensorsHandle=simGetObjectHandle('KCMsgSensor')
	
		-- Check if we have more than one controller in the scene:
		i=0
		cnt=0
		while true do
			h=simGetObjects(i,sim_handle_all)
			if h==-1 then break end
			if simGetObjectCustomData(h,4568)=='kilobotcontroller' then
				cnt=cnt+1
			end
			i=i+1
		end
		if cnt>1 then
			simDisplayDialog('Error',"There is more than one Kilobot controller in the scene.&&nSimulation will not run properly.",sim_dlgstyle_ok,false,nil,{0.8,0.3,0,0,0,0},{0.5,0.25,0,1,1,1})
		end
	
	end
	
	simHandleChildScripts(sim_call_type)

------------------------------------------------------------------------------ 
	--GLOBAL VARIABLES
	message = {msg_type = MSG_TYPE_NORMAL, data = {0, 0, 0, 0, 0, 0, 0, 0, 0}}


	-- get pushed button 
	buttonID=simGetUIEventButton(uiCtrl)
------------------------------------------------------------------------------ 
	
	-- test Run button
	if (buttonID==3) then
		message["msg_type"] = MSG_TYPE_RUN
		--simAddStatusbarMessage(simGetScriptName(sim_handle_self).." send Run") 
	elseif (buttonID==4) then
	-- test Pause button
		message["msg_type"] = MSG_TYPE_PAUSE
		--simAddStatusbarMessage(simGetScriptName(sim_handle_self).." send Pause") 
	elseif (buttonID==5) then
	-- charge 	
		message["msg_type"] = MSG_TYPE_CHARGE
		--simAddStatusbarMessage(simGetScriptName(sim_handle_self).." send Charge") 
	elseif (buttonID==6) then
	-- Bat Volt
		message["msg_type"] = MSG_TYPE_VOLTAGE
		--simAddStatusbarMessage(simGetScriptName(sim_handle_self).." send Bat Volt") 
	elseif (buttonID==10) then
	-- reset
		message["msg_type"] = MSG_TYPE_RESET
		--simAddStatusbarMessage(simGetScriptName(sim_handle_self).." send Reset") 
	end
	
	if (buttonID == 3 or buttonID == 4 or buttonID == 5 or buttonID == 6 or buttonID == 10) then
		--serialize (msg_type, data[1], data[2], ... data[9]) and send message
		simSendData(sim_handle_all,0,"Message",
			simPackInts({message["msg_type"], message["data"][1], message["data"][2], message["data"][3], message["data"][4], message["data"][5],
				message["data"][6], message["data"][7], message["data"][8], message["data"][9]}),
			MsgSensorsHandle,3.00,3.1415,3.1415*2,0.3)
	end
	
	if (simGetSimulationState()==sim_simulation_advancing_lastbeforestop) then
	
		-- Put some restoration code here
	
	end
 
 
------------------------------------------------------------------------------ 
-- Following few lines automatically added by V-REP to guarantee compatibility 
-- with V-REP 3.1.3 and later: 
end 
------------------------------------------------------------------------------ 
