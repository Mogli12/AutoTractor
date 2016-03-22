AutoSteeringEngine = {}

ASECurrentModDir = g_currentModDirectory
ASEModsDirectory = g_modsDirectory.."/"

local ASEFrontPackerT = {}
local ASEFrontPackerC = 0

function AutoSteeringEngine.globalsReset( createIfMissing )

	ASEGlobals = {}
	ASEGlobals.devFeatures  = 0
	ASEGlobals.staticRoot   = 0
	ASEGlobals.chainMax     = 0
	ASEGlobals.chainFix     = 0
	ASEGlobals.chainMin     = 0
	ASEGlobals.chainAvg     = 0
	ASEGlobals.chainAvgFix  = 0
	ASEGlobals.chainLen     = 0
	ASEGlobals.chainLenInc  = 0
	ASEGlobals.chainLenMax  = 0
	ASEGlobals.chain2Len    = 0
	ASEGlobals.chain2LenInc = 0
	ASEGlobals.chain2LenMax = 0
	ASEGlobals.chainStart   = 0
	ASEGlobals.chainDivide  = 0
	ASEGlobals.chainDivide2 = 0
	ASEGlobals.chainSplit   = 0
	ASEGlobals.lookAhead    = 0
	ASEGlobals.lookAheadFix = 0
	ASEGlobals.checkAllDist = 0
	ASEGlobals.widthDec     = 0
	ASEGlobals.widthMaxDec  = 0
	ASEGlobals.angleStep    = 0
	ASEGlobals.angleStepDec = 0
	ASEGlobals.angleFactorNoFix = 0
	ASEGlobals.angleSafety  = 0
	ASEGlobals.maxLooking   = 0
	ASEGlobals.minLooking   = 0
	ASEGlobals.maxRotationC = 0
	ASEGlobals.maxRotationU = 0
	ASEGlobals.minRadius    = 0
	ASEGlobals.aiSteering   = 0
	ASEGlobals.aiSteeringD  = 0
	ASEGlobals.artSteering  = 0
	ASEGlobals.artSteeringD = 0
  ASEGlobals.average      = 0
  ASEGlobals.offtracking  = 0
  ASEGlobals.reverseDir   = 0
	ASEGlobals.minMidDist   = 0
	ASEGlobals.showTrace    = 0
	ASEGlobals.minLength    = 0
	ASEGlobals.roueSupport  = 0
	ASEGlobals.artAxisMode  = 0
	ASEGlobals.artAxisRot   = 0
	ASEGlobals.artAxisShift = 0
	ASEGlobals.showChannels = 0
	ASEGlobals.stepLog2     = 0
	ASEGlobals.yieldCount   = 0
	ASEGlobals.zeroAngle    = 0
	ASEGlobals.colliMask    = 0
	ASEGlobals.fruitIgnoreSq= 0
	ASEGlobals.chainIgnoreSq= 0
	ASEGlobals.ignoreDist   = 0
	ASEGlobals.colliStep    = 0
	ASEGlobals.getIsHired   = 0
	ASEGlobals.angleOffset  = 0
	ASEGlobals.angleOutsideFactor = 0
	ASEGlobals.angleInsideFactor  = 0
	ASEGlobals.angleInsideFactor2 = 0
	ASEGlobals.widthOffset  = 0
	ASEGlobals.shiftFixZ    = 0
	ASEGlobals.zeroWidth    = 0
	ASEGlobals.chainBorder  = 0
	ASEGlobals.stepBack     = 0
	ASEGlobals.smoothFactor = 0
	ASEGlobals.smoothMax    = 0
	ASEGlobals.limitOutside = 0
	ASEGlobals.limitInside  = 0
	ASEGlobals.maxDetectWidth  = 0
	ASEGlobals.maxDetectWidth2 = 0
	ASEGlobals.maxDtSumT     = 0
	ASEGlobals.maxDtSum      = 0
	ASEGlobals.maxDtDist     = 0
	ASEGlobals.showStat      = 0
	ASEGlobals.ploughTransport = 0
	ASEGlobals.maxSpeed      = 0
	ASEGlobals.maxTurnCheck  = 0
	ASEGlobals.maxToolAngle  = 0
	ASEGlobals.maxToolAngle2 = 0
	ASEGlobals.maxToolAngleF = 0
	ASEGlobals.enableYUTurn  = 0
	ASEGlobals.aiRescueDistSq= 0
	ASEGlobals.raiseNoFruits = 0
	ASEGlobals.lowerAdvance  = 0
	ASEGlobals.showInfo      = 0
	
	local file
	file = ASECurrentModDir.."autoSteeringEngineConfig.xml"
	if fileExists(file) then	
		AutoSteeringEngine.globalsLoad( file )	
	else
		print("ERROR: NO GLOBALS IN "..file)
	end
	
	file = ASEModsDirectory.."autoSteeringEngineConfig.xml"
	if fileExists(file) then	
		AutoSteeringEngine.globalsLoad( file )	
	elseif createIfMissing then
		AutoSteeringEngine.globalsCreate()
	end
	
	print("AutoSteeringEngine initialized")
end
	
function AutoSteeringEngine.globalsLoad( file )	

	local xmlFile = loadXMLFile( "ASE", file, "ASEGlobals" )
	for name,value in pairs(ASEGlobals) do
		local tp = Utils.getNoNil( getXMLString(xmlFile, "ASEGlobals." .. name .. "#type"), "int" )
		if     tp == "bool" then
			local bool = getXMLBool( xmlFile, "ASEGlobals." .. name .. "#value" )
			if bool ~= nil then
				if bool then ASEGlobals[name] = 1 else ASEGlobals[name] = 0 end
			end
			--print(file..": "..name.." = "..ASEGlobals[name])
		elseif tp == "float" then
			local float = getXMLFloat( xmlFile, "ASEGlobals." .. name .. "#value" )
			if float ~= nil then ASEGlobals[name] = float end
			--print(file..": "..name.." = "..ASEGlobals[name])
		elseif tp == "degree" then
			local float = getXMLFloat( xmlFile, "ASEGlobals." .. name .. "#value" )
			if float ~= nil then ASEGlobals[name] = math.rad( float ) end
			--print(file..": "..name.." = "..ASEGlobals[name])
		elseif tp == "int" then
			local int = getXMLInt( xmlFile, "ASEGlobals." .. name .. "#value" )
			if int ~= nil then ASEGlobals[name] = int end
			--print(file..": "..name.." = "..ASEGlobals[name])
		else
			print(file..": "..name..": invalid XML type : "..tp)
		end
	end
end

function AutoSteeringEngine.globalsCreate()	

	local file = g_modsDirectory.."/autoSteeringEngineConfig.xml"

	local xmlFile = createXMLFile( "ASE", file, "ASEGlobals" )
	for name,value in pairs(ASEGlobals) do
		if     value == 0 then
			setXMLString( xmlFile, "ASEGlobals." .. name .. "#type", "bool" )
			setXMLBool( xmlFile, "ASEGlobals." .. name .. "#value", false )
		elseif value == 1 then
			setXMLString( xmlFile, "ASEGlobals." .. name .. "#type", "bool" )
			setXMLBool( xmlFile, "ASEGlobals." .. name .. "#value", true )
		elseif math.abs( value - math.floor( value ) ) > 1E-6 then
			setXMLString( xmlFile, "ASEGlobals." .. name .. "#type", "float" )
			setXMLFloat( xmlFile, "ASEGlobals." .. name .. "#value", value )
		else 
			setXMLInt( xmlFile, "ASEGlobals." .. name .. "#value", value )
		end
	end
	
	saveXMLFile(xmlFile)	
end
	

AutoSteeringEngine.resetCounter = 0
AutoSteeringEngine.globalsReset( false )

ASEStatus = {}
ASEStatus.initial  = 0
ASEStatus.steering = 1
ASEStatus.rotation = 2
ASEStatus.position = 3


------------------------------------------------------------------------
-- syncRootNode
------------------------------------------------------------------------
function AutoSteeringEngine.syncRootNode( vehicle, force )

	if ASEGlobals.staticRoot <= 0 then
		return false
	end

	if force or vehicle.acLast == nil or vehicle.acLast.co == nil then 		
		local x0, y0, z0 = getWorldTranslation( g_currentMission.terrainRootNode )
		local x1, y1, z1 = AutoSteeringEngine.getAiWorldPosition( vehicle )
		x1 = x1 - x0
		y1 = y1 - y0
		z1 = z1 - z0
		local x2, y2, z2 = getTranslation( vehicle.aseChain.rootNode )
		if     math.abs( x1-x2 ) > 1E-2 
				or math.abs( y1-y2 ) > 1E-2 
				or math.abs( z1-z2 ) > 1E-2 then 
			vehicle.aseChain.valid = false 
			setTranslation( vehicle.aseChain.rootNode, x1, y1, z1 )
		end 
		
		x0, y0, z0 = getWorldRotation( g_currentMission.terrainRootNode )
		x1, y1, z1 = getWorldRotation( vehicle.aseChain.refNode )
		x1 = x1 - x0
		y1 = y1 - y0
		z1 = z1 - z0
		local x2, y2, z2 = getRotation( vehicle.aseChain.rootNode )
		if     math.abs( x1-x2 ) > 1E-3 
				or math.abs( y1-y2 ) > 1E-3 
				or math.abs( z1-z2 ) > 1E-3 then 
			vehicle.aseChain.valid = false 
			setRotation( vehicle.aseChain.rootNode, x1, y1, z1 )
		end 
		
		AutoSteeringEngine.setChainStatus( vehicle, 1, ASEStatus.rotation )
		
		return true
	end
	
	return false
end 

------------------------------------------------------------------------
-- getAiWorldPosition
------------------------------------------------------------------------
function AutoSteeringEngine.getAiWorldPosition( vehicle )
	if      vehicle.acAiPos      ~= nil
			and vehicle.acParameters ~= nil 
			and vehicle.acParameters.enabled 
			and vehicle.isServer 
			and vehicle.isAITractorActivated then
		return unpack( vehicle.acAiPos )
	end
	return getWorldTranslation( vehicle.aseChain.refNode )
end

------------------------------------------------------------------------
-- getIsAtEnd
------------------------------------------------------------------------
function AutoSteeringEngine.getIsAtEnd( vehicle )
	for i=ASEGlobals.chainMax,2,-1 do 
		if vehicle.aseChain.nodes[i].detected then
			return false
		end
	--if vehicle.aseChain.nodes[i].distance < 2.5 then
	--	break
	--end
	end
	
	return true
end
		
------------------------------------------------------------------------
-- getChainResult
------------------------------------------------------------------------
function AutoSteeringEngine.getChainResult( vehicle, detected, border, indexMax )

	local avg = nil
	
	vehicle.aseLastIndexMax = indexMax 
	
	if     indexMax <= 1 then
		avg = 0
	elseif ASEGlobals.chainAvgFix > 0 or AutoSteeringEngine.getNoReverseIndex( vehicle ) > 0 or not AutoSteeringEngine.noTurnAtEnd( vehicle ) then
		local avgMax, avgMax2 = nil, nil
		for i=1,indexMax do 
			if vehicle.aseChain.nodes[i].isField then
				if avg == nil then
					avg = i
				end
				if vehicle.aseChain.nodes[i].hasBorder then 
					avgMax = i
				end
				avgMax2 = i
			end
		end
		
		if avgMax == nil then	
			avgMax = avgMax2 
		end
		
		if avg == nil then 
			avg = 0
		elseif ASEGlobals.chainAvg > 1 then
			local avgMin = 1		
				while avgMin < ASEGlobals.chainAvg and vehicle.aseChain.nodes[avgMin].distance < -vehicle.aseDistance do
					avgMin = avgMin + 1
				end
			
			if avg < avgMin then
				avg = math.min( avgMin, avgMax )
			end
			avg = Utils.clamp( avg - 1, 1, ASEGlobals.chainAvg )
		else
			avg = 1
		end
	else 
		avg = 0 
	end 
	
	local angle = vehicle.aseChain.nodes[1].steering
	
	if ASEGlobals.chainAvg > 0 and avg >= 1 and math.abs( angle ) > 1E-3 and vehicle.aseDistance < 0 then
		local xw1,yw1,zw1 = AutoSteeringEngine.getAiWorldPosition( vehicle )
		local xw2,yw2,zw2 = getWorldTranslation( vehicle.aseChain.nodes[avg+1].index )
		if avg < indexMax then
			local xw3,yw3,zw3 = getWorldTranslation( vehicle.aseChain.nodes[avg+2].index )
			xw2 = xw2 + 0.5 * ( xw3 - xw2 )
			yw2 = yw2 + 0.5 * ( yw3 - yw2 )
			zw2 = zw2 + 0.5 * ( zw3 - zw2 )
		end
		
	--if vehicle.aseSmooth == nil or vehicle.aseChain.PointBuffer == nil then
	--	vehicle.aseChain.PointBuffer = {{ x=xw2, y=yw2, z=zw2 }}
	--else
	--	local newBuffer = {}
	--	for _,p in pairs(vehicle.aseChain.PointBuffer) do
	--		if Utils.vector3LengthSq( p.x-xw2,p.y-yw2,p.z-zw2 ) < 0.008 then
	--			table.insert( newBuffer, p )
	--		end
	--	end
	--	vehicle.aseChain.PointBuffer = newBuffer		
	--	table.insert( vehicle.aseChain.PointBuffer, { x=xw2, y=yw2, z=zw2 } )
	--end
	--
	--if table.getn( vehicle.aseChain.PointBuffer ) > 1 then
	--	xw2 = 0
	--	yw2 = 0
	--	zw2 = 0
	--	for _,p in pairs(vehicle.aseChain.PointBuffer) do
	--		xw2 = xw2 + p.x
	--		yw2 = yw2 + p.y
	--		zw2 = zw2 + p.z
	--	end
	--	xw2 = xw2 / table.getn( vehicle.aseChain.PointBuffer ) 
	--	yw2 = yw2 / table.getn( vehicle.aseChain.PointBuffer ) 
	--	zw2 = zw2 / table.getn( vehicle.aseChain.PointBuffer ) 
	--end
		
		local dirx,_,dirz = worldDirectionToLocal( vehicle.aseChain.refNode, xw2-xw1, yw2-yw1, zw2-zw1 )
		local d = dirx*dirx + dirz*dirz
		if d > 1E-3 then
			angle = math.atan( 2 * dirx * vehicle.aseChain.wheelBase / d )
		end
	end
	
	if vehicle.aseLRSwitch	then
		angle = angle + ASEGlobals.angleOffset
	else
		angle = angle - ASEGlobals.angleOffset
	end 
	
	angle = Utils.clamp( angle, vehicle.aseMinAngle, vehicle.aseMaxAngle )
	
	if border > 0 then
		if ASEGlobals.devFeatures > 0 then 
			print("============================= "..tostring(border).." "..tostring(detected))
		end
		for _,tp in pairs(vehicle.aseToolParams) do
			if tp.skip then
				if ASEGlobals.devFeatures > 0 then 
					print(tostring(tp.i).." is skipped")
				end
			else
				local b, t = AutoSteeringEngine.getChainBorder( vehicle, ASEGlobals.chainStart, indexMax, tp )
				if ASEGlobals.devFeatures > 0 then 
					print(tostring(tp.i)..": "..tostring(b)..": "..tostring(t).." ("..tostring(vehicle.aseTools[tp.i].aiProhibitedFruitType)..")")
				end
				tp.noEmptyBorder = ( b > 0 )
			end
		end
	end			
	
	return detected, angle, border
end

------------------------------------------------------------------------
-- processChainNewGetAngle
------------------------------------------------------------------------
function AutoSteeringEngine.processChainNewGetAngle( nodes, index, from, current, to )
	if nodes[index].angle >= 0 or from == to then
		return nodes[index].angle 
	end
	if current == from then
		return nodes[index].angle
	end
	if current > from + 2 then
		return 0
	end
	if current == from + 1 and current == to then
		return -nodes[index].angle
	end
	local a = nodes[index].angle
	a = -a*(1+a+a)
	if current == from + 1 then
		return a
	end
	-- current == from + 2
	return -nodes[index].angle-a
end

-----------------------------------------------------------------------
-- processChainNewGetBorder
------------------------------------------------------------------------
function AutoSteeringEngine.processChainNewGetBorder( vehicle, nodes, index, level, upToLevel, round )

	local to = math.min( level + math.max( round, nodes[index].lookAhead ), upToLevel )
	local fr = level
	if nodes[index].to == nil then
		nodes[index].border   = 0
	else
		fr = nodes[index].to + 1
	end
		
	if fr <= to then
		for l=level,to do
			vehicle.aseChain.nodes[l].angle = AutoSteeringEngine.processChainNewGetAngle( nodes, index, level, l, to )
		end
		AutoSteeringEngine.setChainStatus( vehicle, level, ASEStatus.initial )
		AutoSteeringEngine.applyRotation( vehicle, to )
		local b, _, d = AutoSteeringEngine.getAllChainBorders( vehicle, fr, to )
		nodes[index].border = nodes[index].border + b
		nodes[index].to     = to
	end

	return nodes[index].border
end

------------------------------------------------------------------------
-- processChainLevelAngle
------------------------------------------------------------------------
function AutoSteeringEngine.processChainLevelAngle( vehicle, factor )
	if factor < -1 or factor > 1 then
		return factor 
	elseif factor < 0 then
		return - factor * factor 
	else
		return factor * factor
	end
	return 0
end

------------------------------------------------------------------------
-- processChainLevel
------------------------------------------------------------------------
function AutoSteeringEngine.processChainLevel( vehicle, angles, upToLevel, lookAheadM, lookAheadP, checkAllDist )

	vehicle.acIamDetecting = true

	local level = table.getn( angles ) + 1
	
	if level >= upToLevel then
		return 0, false, angles  
	end
	
	local trace = {}
	
	local newAngles = {}
	local nodes     = {}
	
	for i,a in pairs( angles ) do
		newAngles[i] = a
		trace[i]     = a
		if math.abs( vehicle.aseChain.nodes[i].angle - a ) > 1e-4 then
			vehicle.aseChain.nodes[i].angle = a
			AutoSteeringEngine.setChainStatus( vehicle, i, ASEStatus.initial )
		end
	end

	local delta      = 1.0 / math.floor( 0.5 + ASEGlobals.chainDivide	- level / ASEGlobals.chainMax * ( ASEGlobals.chainDivide2 - ASEGlobals.chainDivide ) )
	local a          = -1
	local minA0      = nil
	local minALast   = nil
	local targetA    = 0 -- -Utils.getNoNil( angles[level-1], 0 )
	local inside     = nil
	local last       = nil
	local mid        = nil

	if vehicle.aseLastBestAngle == nil then
		vehicle.aseLastBestAngle = {}
	elseif vehicle.aseLastBestAngle[level] ~= nil then
		targetA = vehicle.aseLastBestAngle[level]
	end
	
	while a <= 1 do
		local node    = {}
		node.angle    = AutoSteeringEngine.processChainLevelAngle( vehicle, a )
		if lookAheadM == lookAheadP then
			node.lookAhead = lookAheadM
		else
			node.lookAhead = math.floor( 0.5 + lookAheadM + 0.5 * ( 1 + a ) * ( lookAheadP - lookAheadM ) )
		end
		node.inside   = inside
		node.index    = table.getn( nodes ) + 1
		if inside ~= nil then
			nodes[inside].outside = node.index 
		end
		inside = node.index
		nodes[node.index] = node
		if minALast == nil or minALast > math.abs(a-targetA) then
			minALast = math.abs(a-targetA)
			last     = node.index 
		end
		if minA0 == nil or minA0 > math.abs(a) then
			minA0 = math.abs(a-targetA)
			mid   = node.index 
		end
			
		a = a + delta
	end
	
	local round = 0
	local nxt 
	local detected = false

	while true do		
		detected   = false
		local d2   = false

		nxt = mid
		local b = AutoSteeringEngine.processChainNewGetBorder( vehicle, nodes, nxt, level, upToLevel, round )
		if b > 0 and mid ~= last then
			nxt = last
			b   = AutoSteeringEngine.processChainNewGetBorder( vehicle, nodes, nxt, level, upToLevel, round )
		end
		
		if b <= 0 then			
			-- nxt is already mid => just in case b <= 0 everywhere 
			d2 = true
		elseif vehicle.aseChain.nodes[level+round].distance < checkAllDist then
			-- find area with b <= 0 nearest to mid
			local tst
			local dir = 1
			while true do
				local d3 = true
				for i=1,2 do
					if i <= 1 then
						tst = last - dir
					else
						tst = last + dir
					end
					if 1 <= tst and tst <= table.getn( nodes ) then
						d3 = false
						b = AutoSteeringEngine.processChainNewGetBorder( vehicle, nodes, tst, level, upToLevel, round )
					
						if b <= 0 then
							nxt = tst
							d2  = true
							break
						else
							detected = true
						end
					end
				end
				if d2 or d3 then
					break
				end
				dir = dir + 1
			end
		else 
			while true do
				b = AutoSteeringEngine.processChainNewGetBorder( vehicle, nodes, nxt, level, upToLevel, round )
				if b <= 0 then
					d2 = true
					break
				end
				detected = true
				if nodes[nxt].outside == nil then
					break
				end
				nxt = nodes[nxt].outside
			end
		end
		
		if d2 then
		-- nxt in the middle of b <= 0
			local rem = nxt
			local tst = nxt
			while true do
				b = AutoSteeringEngine.processChainNewGetBorder( vehicle, nodes, tst, level, upToLevel, round )				
				if b > 0 then
					detected = true
					break
				else
					nxt = tst
				end
				if nodes[tst].inside == nil then
					break
				else
					tst = nodes[tst].inside
				end
			end
			
			if not detected then
				nxt = rem
			end
		else
		-- b > 0 everywhere
			nxt = table.getn( nodes )
		end

		
		b = AutoSteeringEngine.processChainNewGetBorder( vehicle, nodes, nxt, level, upToLevel, round )
		
		if detected then
			vehicle.aseChain.nodes[level+round].detected = true
		end
		
		if level+round >= upToLevel then			
			if b > 0 or detected then
				for i=level,upToLevel do
					newAngles[i] = AutoSteeringEngine.processChainNewGetAngle( nodes, nxt, level, i, level+round )
				end
			else
				AutoSteeringEngine.setChainStatus( vehicle, level, ASEStatus.initial )
				AutoSteeringEngine.setChainStraight( vehicle, level )
				for i=level,upToLevel do
					newAngles[i] = vehicle.aseChain.nodes[i].angle
				end
			end
			vehicle.aseLastBestAngle[level] = newAngles[level]
			return b, detected, newAngles
		elseif detected then
			break
		end
		
		round = round + 1
	end	
	
	local bestB  = nil
	local bestN  = nxt
	local dLevel = detected 
	local dNext  = false
	
	while true do
		local b, d, t
		for i=0,round do
			newAngles[level+i] = AutoSteeringEngine.processChainNewGetAngle( nodes, nxt, level, level+i, level+round )
		end
		b = AutoSteeringEngine.processChainNewGetBorder( vehicle, nodes, nxt, level, upToLevel, round )
		if b > 0 then
			vehicle.aseLastBestAngle[level] = newAngles[level]
			return b, true, newAngles
		end
		b, d, t = AutoSteeringEngine.processChainLevel( vehicle, newAngles, upToLevel, lookAheadM, lookAheadP, checkAllDist )
		detected = detected or d
		dNext    = dNext    or d
		if b <= 0 then
			if not dNext and level + round > 1 and dLevel then
				-- do not take the last one if there was nothing found behind
				AutoSteeringEngine.setChainStatus( vehicle, level + round, ASEStatus.initial )
				AutoSteeringEngine.setChainStraight( vehicle, level + round )
				newAngles[level+round] = nil
				return 0, true, newAngles
			else
				return b, detected, t 
			end
		elseif nodes[nxt].outside == nil then	
			vehicle.aseLastBestAngle[level] = t[level]
			return b, detected, t 
		end
		nxt = nodes[nxt].outside
	end
	
	print("ERROR: We should never come here")
	
	vehicle.aseLastBestAngle[level] = nil
	return 99, false, angles

end

------------------------------------------------------------------------
-- processChainNew
------------------------------------------------------------------------
function AutoSteeringEngine.processChain( vehicle, smooth, withYield )

	if not vehicle.isServer then return false,0,0 end
	
	local detected  = false
	local indexMax = ASEGlobals.chainFix
	if AutoSteeringEngine.getNoReverseIndex( vehicle ) > 0 or AutoSteeringEngine.noTurnAtEnd( vehicle ) then 
		indexMax = ASEGlobals.chainMax
	end
	
	if vehicle.aseToolParams == nil or table.getn( vehicle.aseToolParams ) < 1 then
		return false, 0,0
	end

	local s = 1 
	if smooth ~= nil and smooth > 0 then
		s = Utils.clamp( 1 - smooth, 0.1, 1 ) 
	end 
	
	vehicle.aseChain.valid = false
	vehicle.aseSmooth      = nil
	
	AutoSteeringEngine.initSteering( vehicle )	
	AutoSteeringEngine.syncRootNode( vehicle, true )
	
	if s < 1 then
		vehicle.aseSmooth      = s
		vehicle.aseAngleFactor = vehicle.aseAngleFactor * vehicle.aseSmooth
	end

	local fixedConnection = false
	for _,tool in pairs( vehicle.aseTools ) do
		if not ( tool.aiForceTurnNoBackward ) then
			fixedConnection = true
		end
	end

	local lookAheadP   = ASEGlobals.lookAhead
	local checkAllDist = ASEGlobals.checkAllDist

	if fixedConnection then
		lookAheadP   = ASEGlobals.lookAheadFix 
		checkAllDist = checkAllDist - math.min( 0, vehicle.aseDistance )
	end
	
	for i=1,ASEGlobals.chainMax do
		vehicle.aseChain.nodes[i].detected = false
	end
	
	local b, d, t = AutoSteeringEngine.processChainLevel( vehicle, {}, indexMax, ASEGlobals.lookAhead, lookAheadP, checkAllDist )
	
	detected = d	
	indexMax = table.getn(t)
	
	if ASEGlobals.devFeatures > 0 and indexMax < 1 then
		print("empty chain I")
	--return false, 0, 178
	end
	
	for i,a in pairs(t) do
		vehicle.aseChain.nodes[i].angle = a
	end
	
	AutoSteeringEngine.setChainStatus( vehicle, 1, ASEStatus.initial )
	AutoSteeringEngine.applyRotation( vehicle, indexMax )	
	local border, total = AutoSteeringEngine.getAllChainBorders( vehicle, ASEGlobals.chainStart, indexMax )

	if ASEGlobals.devFeatures > 0 and total <= 0 then
		print("empty chain II")
	--return false, 0, 178
	end
	
	local chainBorder = ASEGlobals.chainMin 
	if vehicle.acTurnStage ~= nil and vehicle.acTurnStage == 0 then
		chainBorder = ASEGlobals.chainBorder 
	end
	
	while border > 0 and indexMax > chainBorder do 
		indexMax      = indexMax - 1 
		border, total = AutoSteeringEngine.getAllChainBorders( vehicle, ASEGlobals.chainStart, indexMax )
		if total <= 0 then
			indexMax      = indexMax + 1 
			border, total = AutoSteeringEngine.getAllChainBorders( vehicle, ASEGlobals.chainStart, indexMax )
			break
		end
	end 
	
	if detected and border <= 0 then 
		vehicle.aseChain.valid = true 
	end 
	
	return AutoSteeringEngine.getChainResult( vehicle, detected, border, indexMax )
end

------------------------------------------------------------------------
-- checkChain
------------------------------------------------------------------------
function AutoSteeringEngine.checkChain( vehicle, iRefNode, zOffset, wheelBase, maxSteering, widthOffset, turnOffset, isInverted, useFrontPacker, speedFactor )

	local resetTools = false
	
	if vehicle.isReverseDriving then
		isInverted = not isInverted
	end

	AutoSteeringEngine.currentSteeringAngle( vehicle, isInverted )

	if     vehicle.aseChain == nil
			or vehicle.aseChain.resetCounter == nil
			or vehicle.aseChain.resetCounter < AutoSteeringEngine.resetCounter then
		AutoSteeringEngine.initChain( vehicle, iRefNode, zOffset, wheelBase, maxSteering, widthOffset, turnOffset )
	else
		vehicle.aseChain.wheelBase   = wheelBase
		vehicle.aseChain.invWheelBase = 1 / wheelBase
		vehicle.aseChain.maxSteering = maxSteering
		if vehicle.aseChain.zOffset ~= zOffset then
			vehicle.aseChain.zOffset   = zOffset
			setTranslation( vehicle.aseChain.refNode, 0,0, vehicle.aseChain.zOffset )
		end
	end	

	if getfenv(0)["modSoilMod2"] == nil then
		if vehicle.aseChain.useFrontPacker ~= nil and vehicle.aseChain.useFrontPacker ~= useFrontPacker then
			resetTools = true
		end
	else
		vehicle.aseChain.useFrontPacker = false
	end

	if maxSteering ~= nil and 1E-4 < maxSteering and maxSteering < 0.5 * math.pi then
		vehicle.aseChain.radius    = wheelBase / math.tan( maxSteering )
	else
		vehicle.aseChain.radius    = 5
	end
	
	vehicle.aseChain.isInverted	    = isInverted
	vehicle.aseChain.useFrontPacker = useFrontPacker 
	
	AutoSteeringEngine.checkTools1( vehicle, resetTools )
	vehicle.aseWantedSpeed          = speedFactor * AutoSteeringEngine.getToolsSpeedLimit( vehicle )
	
end

------------------------------------------------------------------------
-- getWidthOffset
------------------------------------------------------------------------
function AutoSteeringEngine.getWidthOffset( vehicle, width, widthOffset, widthFactor )
	local offset = 0
	if ASEGlobals.widthOffset > 0 then 
		local scale  = Utils.getNoNil( vehicle.aiTurnWidthScale, 0.95 )
		local diff   = Utils.getNoNil( vehicle.aiTurnWidthMaxDifference, 0.5 )
		offset = ASEGlobals.widthOffset * 0.5 * ( width - math.max(width * scale, width - diff) )
		if widthFactor ~= nil then
			offset = widthFactor * offset
		end
	end
	--offset = 0
	if widthOffset ~= nil then
		offset = offset - widthOffset
	end
	return offset
end

------------------------------------------------------------------------
-- addToolsRec
------------------------------------------------------------------------
function AutoSteeringEngine.addToolsRec( vehicle, obj )
	if obj ~= nil and obj.attachedImplements ~= nil then
		for _, implement in pairs(obj.attachedImplements) do
			if      implement.object                    ~= nil 
					and implement.object.attacherJoint      ~= nil 
					and implement.object.attacherJoint.node ~= nil then					
				local iCultivator = AutoSteeringEngine.addTool( vehicle,implement )
				if      vehicle.aseChain.useFrontPacker
						and iCultivator > 0
						and SpecializationUtil.hasSpecialization(Cultivator, implement.object.specializations) then
				--vehicle.aseTools[iCultivator].aiTerrainDetailChannel1 = g_currentMission.ploughChannel
				--vehicle.aseTools[iCultivator].aiTerrainDetailChannel2 = -1
				--vehicle.aseTools[iCultivator].aiTerrainDetailChannel3 = -1
					AutoSteeringEngine.registerFrontPacker( implement.object )
				end
				AutoSteeringEngine.addToolsRec( vehicle, implement.object )
			end
		end	
	end
end

------------------------------------------------------------------------
-- checkTools
------------------------------------------------------------------------
function AutoSteeringEngine.checkTools1( vehicle, reset )

	if vehicle.aseChain ~= nil and ( vehicle.aseTools == nil or reset ) then
		AutoSteeringEngine.resetFrontPacker( vehicle )
		AutoSteeringEngine.deleteTools( vehicle )
		vehicle.aseCollisions = nil
		vehicle.aseLastBestAngle = nil
		
		AutoSteeringEngine.addToolsRec( vehicle, vehicle )
		
		if vehicle.aseTools == nil then
			AutoSteeringEngine.addTool(vehicle,nil,vehicle,vehicle.aseChain.refNode)
		end
		
		if vehicle.aseTools == nil then
			vehicle.aseTools = {}
		end
	end
end
function AutoSteeringEngine.checkTools( vehicle, reset )
	
	AutoSteeringEngine.checkTools1( vehicle, reset )
	
	local dx,dz,zb = 0,0,0
	
	if ( vehicle.aseChain ~= nil and vehicle.aseLRSwitch ~= nil and vehicle.aseToolCount ~= nil and vehicle.aseToolCount >= 1 ) then
		dz = -99
		zb =  99
		for i=1,vehicle.aseToolCount do
			local doNotIgnore = true
			if vehicle.aseTools[i].ignoreAI then
				doNotIgnore = false
			end
		--if ASEFrontPackerT[vehicle.aseTools[i].obj] then
		--if vehicle.aseHas.sowingMachine and vehicle.aseTools[i].isCultivator then
		--	doNotIgnore = false
		--end
			if doNotIgnore then
				local _,_,zDist   = AutoSteeringEngine.getRelativeTranslation( vehicle.aseChain.refNode, vehicle.aseTools[i].refNode )
				
				local dx1 = vehicle.aseTools[i].xl-vehicle.aseTools[i].xr
				local dz1 = vehicle.aseTools[i].z  + zDist
				local zb1 = vehicle.aseTools[i].zb + zDist
				if vehicle.aseTools[i].isSprayer and zb1 < dz1 then
					zb1 = dz1 -1
				end
				
				if dx < dx1 then dx = dx1 end
				if dz < dz1 then dz = dz1 end
				if zb > zb1 then zb = zb1 end
				
			end
			local wo = AutoSteeringEngine.getWidthOffset( vehicle, dx )
			dx = 0.5 * dx - wo
		end
	end
	
	return dx,dz,zb
end

------------------------------------------------------------------------
-- getToolsSpeedLimit
------------------------------------------------------------------------
function AutoSteeringEngine.getToolsSpeedLimit( vehicle )

	local speedLimit = 25
	if vehicle.cruiseControl ~= nil and vehicle.cruiseControl.maxSpeed ~= nil then
		speedLimit = vehicle.cruiseControl.maxSpeed
	end
	if vehicle.checkSpeedLimit and speedLimit > vehicle.speedLimit then
		speedLimit = vehicle.speedLimit
	end
	
	if ( vehicle.aseChain ~= nil and vehicle.aseLRSwitch ~= nil and vehicle.aseToolCount ~= nil and vehicle.aseToolCount >= 1 ) then
		for i=1,vehicle.aseToolCount do
			object = vehicle.aseTools[i].obj
			if object.checkSpeedLimit and speedLimit > object.speedLimit then
				speedLimit = object.speedLimit
			end
		end
	end
	
	return speedLimit
end

------------------------------------------------------------------------
-- getWantedSpeed
------------------------------------------------------------------------
function AutoSteeringEngine.getWantedSpeed( vehicle, speedLevel )
	if vehicle.aseWantedSpeed == nil then
		vehicle.aseWantedSpeed = 0.8 *  AutoSteeringEngine.getToolsSpeedLimit( vehicle )
	end
	
	local wantedSpeed  = 12
		
	if     speedLevel == nil 
			or speedLevel == 2 then
		wantedSpeed = vehicle.aseWantedSpeed
	elseif speedLevel == 4 then
		wantedSpeed = 7
--elseif speedLevel == 1 then
--	wantedSpeed = 12
--elseif speedLevel == 2 then
--	wantedSpeed = 18
--elseif speedLevel == 3 then
--	wantedSpeed = 30
	elseif speedLevel == 5 then
		wantedSpeed = 1
	elseif speedLevel == 0 then
		wantedSpeed = 0
	elseif speedLevel == 1 then
		wantedSpeed  = 0.667 * vehicle.aseWantedSpeed
	end
				
	return wantedSpeed
end

------------------------------------------------------------------------
-- hasTools
------------------------------------------------------------------------
function AutoSteeringEngine.hasTools( vehicle )
	if      vehicle.aseChain     ~= nil 
			and vehicle.aseLRSwitch  ~= nil 
			and vehicle.aseToolCount ~= nil 
			and vehicle.aseToolCount >= 1 then 
		for _,t in pairs(vehicle.aseTools) do
			if not (t.ignoreAI) then
				return true
			end
		end
	end
	return false 
end

------------------------------------------------------------------------
-- initTools
------------------------------------------------------------------------
function AutoSteeringEngine.initTools( vehicle, maxLooking, leftActive, widthOffset, headlandDist, collisionDist, turnMode )

	isTurnMode7 = ( vehicle.aseTurnMode == "7" )
	
	if isTurnMode7 then
		if     vehicle.aseLRSwitch    == nil or vehicle.aseLRSwitch    ~= leftActive
				or vehicle.aseIsTurnMode7 == nil or vehicle.aseIsTurnMode7 ~= isTurnMode7 then
			AutoSteeringEngine.setChainStatus( vehicle, 1, ASEStatus.initial )
		end
	elseif vehicle.aseLRSwitch == nil or vehicle.aseLRSwitch ~= leftActive
			or vehicle.aseHeadland == nil or vehicle.aseHeadland ~= headlandDist then
		AutoSteeringEngine.setChainStatus( vehicle, 1, ASEStatus.initial )
	end
	
	vehicle.aseIsTurnMode7 = isTurnMode7
	
	vehicle.aseLRSwitch    = leftActive
	vehicle.aseHeadland    = headlandDist
	vehicle.aseTurnMode    = turnMode
	vehicle.aseMaxLooking  = maxLooking
	
	if     vehicle.aseTurnMode == "C"
			or vehicle.aseTurnMode == "L"
			or vehicle.aseTurnMode == "K"
			or vehicle.aseTurnMode == "7" then
		vehicle.aseMaxRotation = ASEGlobals.maxRotationC
	else 
		vehicle.aseMaxRotation = ASEGlobals.maxRotationU
	end 
	
	if collisionDist > 1 then
		vehicle.aseCollision = collisionDist 
	else
		vehicle.aseCollision =  0
	end
	vehicle.aseToolParams  = {}
		
	local currentSeed = nil
	if vehicle.aseHas.sowingMachine then
		for _,tool in pairs(vehicle.aseTools) do
			if tool.isSowingMachine then
				currentSeed = tool.obj.seeds[tool.obj.currentSeed]
			end
		end
	end
	
	if ( vehicle.aseChain ~= nil and vehicle.aseLRSwitch ~= nil and vehicle.aseToolCount ~= nil and vehicle.aseToolCount >= 1 ) then	
		for i,tool in pairs(vehicle.aseTools) do
			local self = tool.obj
			
			if     tool.specialType == "Horsch SW3500 S" then
				vehicle.aseTools[i].aiProhibitedFruitType      = self.currentFillType
				if vehicle.aseTools[i].aiProhibitedFruitType ~= FruitUtil.FRUITTYPE_UNKNOWN then
					vehicle.aseTools[i].aiProhibitedMinGrowthState = 0
					vehicle.aseTools[i].aiProhibitedMaxGrowthState = FruitUtil.fruitIndexToDesc[vehicle.aseTools[i].aiProhibitedFruitType].maxHarvestingGrowthState			
				end
			elseif tool.isSowingMachine then
				vehicle.aseTools[i].aiTerrainDetailChannel1 = g_currentMission.cultivatorChannel
				vehicle.aseTools[i].aiTerrainDetailChannel2 = g_currentMission.ploughChannel
				if self.useDirectPlanting and currentSeed ~= nil then
					vehicle.aseTools[i].aiTerrainDetailChannel3       = g_currentMission.sowingChannel
					vehicle.aseTools[i].aiTerrainDetailProhibitedMask = 0
					vehicle.aseTools[i].aiProhibitedFruitType         = currentSeed
					vehicle.aseTools[i].aiProhibitedMinGrowthState    = 0
					vehicle.aseTools[i].aiProhibitedMaxGrowthState    = FruitUtil.fruitIndexToDesc[vehicle.aseTools[i].aiProhibitedFruitType].maxHarvestingGrowthState
				else
					vehicle.aseTools[i].aiTerrainDetailChannel3       = -1
					vehicle.aseTools[i].aiTerrainDetailProhibitedMask = bitOR(2^g_currentMission.sowingChannel, 2^g_currentMission.sowingWidthChannel)
					vehicle.aseTools[i].aiProhibitedFruitType         = FruitUtil.FRUITTYPE_UNKNOWN
					vehicle.aseTools[i].aiProhibitedMinGrowthState    = 0
					vehicle.aseTools[i].aiProhibitedMaxGrowthState    = 0
				end
			elseif tool.isAITool then
				vehicle.aseTools[i].aiTerrainDetailChannel1       = Utils.getNoNil( tool.obj.aiTerrainDetailChannel1      ,-1 )
				vehicle.aseTools[i].aiTerrainDetailChannel2       = Utils.getNoNil( tool.obj.aiTerrainDetailChannel2      ,-1 )
				vehicle.aseTools[i].aiTerrainDetailChannel3       = Utils.getNoNil( tool.obj.aiTerrainDetailChannel3      ,-1 )
				vehicle.aseTools[i].aiTerrainDetailChannel4       = Utils.getNoNil( tool.obj.aiTerrainDetailChannel4      ,-1 )
				vehicle.aseTools[i].aiTerrainDetailProhibitedMask = Utils.getNoNil( tool.obj.aiTerrainDetailProhibitedMask,0 )
				vehicle.aseTools[i].aiRequiredFruitType           = Utils.getNoNil( tool.obj.aiRequiredFruitType          ,FruitUtil.FRUITTYPE_UNKNOWN )
				vehicle.aseTools[i].aiRequiredMinGrowthState      = Utils.getNoNil( tool.obj.aiRequiredMinGrowthState     ,0 )
				vehicle.aseTools[i].aiRequiredMaxGrowthState      = Utils.getNoNil( tool.obj.aiRequiredMaxGrowthState     ,0 )
				vehicle.aseTools[i].aiProhibitedFruitType         = Utils.getNoNil( tool.obj.aiProhibitedFruitType        ,FruitUtil.FRUITTYPE_UNKNOWN )
				vehicle.aseTools[i].aiProhibitedMinGrowthState    = Utils.getNoNil( tool.obj.aiProhibitedMinGrowthState   ,0 )
				vehicle.aseTools[i].aiProhibitedMaxGrowthState    = Utils.getNoNil( tool.obj.aiProhibitedMaxGrowthState   ,0 )
			end
			
			if tool.obj.aiForceTurnNoBackward then
				vehicle.aseTools[i].aiForceTurnNoBackward = true
			end
			
			if      vehicle.aseHas.cultivator 
					and not tool.isCultivator
					and not tool.isSowingMachine
					and not tool.isSprayer then
				AutoSteeringEngine.removeTerrainDetailChannel( vehicle.aseTools[i], g_currentMission.cultivatorChannel )
			end 
			if      currentSeed ~= nil
					and ( ASEFrontPackerT[tool.obj]
						or ( vehicle.aseHas.sowingMachine
						 and not tool.isSowingMachine
						 and not tool.isSprayer ) ) then
				AutoSteeringEngine.removeTerrainDetailChannel( vehicle.aseTools[i], g_currentMission.sowingChannel )
				AutoSteeringEngine.removeTerrainDetailChannel( vehicle.aseTools[i], g_currentMission.sowingWidthChannel )
			--vehicle.aseTools[i].aiProhibitedFruitType         = currentSeed
			--vehicle.aseTools[i].aiProhibitedMinGrowthState    = 0
			--vehicle.aseTools[i].aiProhibitedMaxGrowthState    = FruitUtil.fruitIndexToDesc[vehicle.aseTools[i].aiProhibitedFruitType].maxHarvestingGrowthState
			end
						
			vehicle.aseTools[i].aiTerrainDetailRequiredMask = AutoSteeringEngine.getTerrainDetailRequiredMask( vehicle.aseTools[i] )
		end
	
		local xa = {}
		local xo = {}
		for i=1,vehicle.aseToolCount do
		
			local skip      = false
			local skipOther = false
			if vehicle.aseTools[i].ignoreAI then
				skip      = true
				skipOther = true
			end

			if      vehicle.aseHas.sowingMachine
					and not ( vehicle.aseTools[i].isSowingMachine )
					and ( ( vehicle.aseTools[i].isCultivator and not AutoSteeringEngine.hasFrontPacker( vehicle ) )
						 or vehicle.aseTools[i].isPlough
						 or vehicle.aseTools[i].isSprayer )
					 then
				skip      = true
				skipOther = true
		--elseif  vehicle.aseHas.plough
		--		and not ( vehicle.aseTools[i].isPlough )
		--		and vehicle.aseTools[i].isCultivator then
		--	skip      = true
		--	skipOther = true
			end
			
			if      not ( vehicle.aseTools[i].isCombine )
					and not ( vehicle.aseTools[i].isMower )
					and not ( vehicle.aseTools[i].isWindrower )
					and not ( vehicle.aseTools[i].isTedder )
					and vehicle.aseTools[i].aiTerrainDetailRequiredMask <= 0
					and vehicle.aseTools[i].aiRequiredFruitType         == FruitUtil.FRUITTYPE_UNKNOWN then
				skip      = true
				skipOther = true
			end
			
			if not skip or not skipOther then
				for j=1,vehicle.aseToolCount do
					if i ~= j then
						if     ( vehicle.aseTools[i].isCombine      
									or vehicle.aseTools[i].isPlough       
									or vehicle.aseTools[i].isCultivator   
									or vehicle.aseTools[i].isSowingMachine
									or vehicle.aseTools[i].isSprayer      
									or vehicle.aseTools[i].isMower        
									or vehicle.aseTools[i].isTedder       
									or vehicle.aseTools[i].isWindrower      
									or vehicle.aseTools[i].outTerrainDetailChannel >= 0
									--or ( vehicle.aseTools[i].specialType ~= nil and vehicle.aseTools[i].specialType ~= "" ) 
									 )
								and not ( vehicle.aseTools[j].ignoreAI )
								and vehicle.aseTools[i].isCombine       == vehicle.aseTools[j].isCombine      
								and vehicle.aseTools[i].isPlough        == vehicle.aseTools[j].isPlough       
								and vehicle.aseTools[i].isCultivator    == vehicle.aseTools[j].isCultivator   
								and vehicle.aseTools[i].isSowingMachine == vehicle.aseTools[j].isSowingMachine
								and vehicle.aseTools[i].isSprayer       == vehicle.aseTools[j].isSprayer      
								and vehicle.aseTools[i].isMower         == vehicle.aseTools[j].isMower        
								and vehicle.aseTools[i].isTedder        == vehicle.aseTools[j].isTedder        
								and vehicle.aseTools[i].isWindrower     == vehicle.aseTools[j].isWindrower        
								and vehicle.aseTools[i].outTerrainDetailChannel == vehicle.aseTools[j].outTerrainDetailChannel 
								--and vehicle.aseTools[i].specialType == vehicle.aseTools[j].specialType
								then
							
							local k = i
							for l=1,2 do
								if xa[k] == nil then	
									local tool = vehicle.aseTools[k]
									local xOffset,_,_ = AutoSteeringEngine.getRelativeTranslation( tool.steeringAxleNode, tool.refNode )
									for m=1,table.getn(tool.marker) do
										local xxx,_,_ = AutoSteeringEngine.getRelativeTranslation( tool.steeringAxleNode, tool.marker[m] )
										xxx = xxx - xOffset
										if tool.invert then xxx = -xxx end
										if xa[k] == nil then
											xa[k] = xxx
											xo[k] = xxx
										elseif vehicle.aseLRSwitch then
											if xa[k] < xxx then xa[k] = xxx end
											if xo[k] > xxx then xo[k] = xxx end
										else
											if xa[k] > xxx then xa[k] = xxx end
											if xo[k] < xxx then xo[k] = xxx end
										end
									end
									local xxx = AutoSteeringEngine.getRelativeTranslation( vehicle.aseChain.refNode, tool.refNode )
									xa[k]  = xa[k] + xxx
									xo[k]  = xo[k] + xxx
								end
								
								k = j
							end
							
							if vehicle.aseLRSwitch then
								skip      = skip      or ( xa[i] + 0.2 < xa[j] )
								skipOther = skipOther or ( xo[i] - 0.2 > xo[j] )
							else
								skip      = skip      or ( xa[i] - 0.2 > xa[j] )
								skipOther = skipOther or ( xo[i] + 0.2 < xo[j] )
							end					
							
							if skip and skipOther then
								break
							end
						end
					end
				end
			end
			
			local tp = AutoSteeringEngine.getSteeringParameterOfTool( vehicle, i, maxLooking, widthOffset )			
			tp.skip      = skip
			tp.skipOther = skipOther
			vehicle.aseToolParams[i] = tp
		end
		
		--for i=1,vehicle.aseToolCount do
		--	if not ( vehicle.aseTools[i].aiForceTurnNoBackward ) and not ( vehicle.aseToolParams[i].skip ) then 
		--		local tp = AutoSteeringEngine.getSteeringParameterOfTool( vehicle, i, maxLooking, widthOffset, 0 )
		--		tp.skip = false 
		--		vehicle.aseToolParams[table.getn(vehicle.aseToolParams)+1] = tp
		--	end 
		--end 
	end	
	
	AutoSteeringEngine.initSteering( vehicle )
end

function AutoSteeringEngine.reinitToolsWithWidthFactor( vehicle, maxLooking, widthOffset, widthFactor )

	if vehicle.aseToolParams ~= nil then
		local tpNew = {}
		for i=1,table.getn( vehicle.aseToolParams ) do
			local tp = AutoSteeringEngine.getSteeringParameterOfTool( vehicle, vehicle.aseToolParams[i].i, maxLooking, widthOffset, widthFactor )
			tp.skip  = vehicle.aseToolParams[i].skip
			tpNew[vehicle.aseToolParams[i].i] = tp
		end
		vehicle.aseToolParams = tpNew
	end
end

------------------------------------------------------------------------
-- AutoSteeringEngineCallback
------------------------------------------------------------------------
AutoSteeringEngineCallback = {}
function AutoSteeringEngineCallback.create( vehicle )
	local self = {}
	self.vehicle = vehicle
	self.raycast = AutoSteeringEngineCallback.raycast
	self.overlap = AutoSteeringEngineCallback.overlap
	return self
end

------------------------------------------------------------------------
-- AutoSteeringEngineCallback:raycast
------------------------------------------------------------------------
function AutoSteeringEngineCallback:raycast( transformId, x, y, z, distance )
	
	if transformId == g_currentMission.terrainRootNode or ( transformId == nil and distance > 1 ) then
		return true
	end

	local other  = nil
	local nodeId = transformId
	repeat
		other  = g_currentMission.nodeToVehicle[nodeId]
		if other == nil then
			nodeId = getParent( nodeId )	
		end
	until other ~= nil or nodeId == nil or nodeId == 0
	
	if     other == nil then
	--	print("static  "..tostring(getName(transformId)).." @ x: "..tostring(x).." z: "..tostring(z))
		self.vehicle.aseHasCollision = true

		if ASECollisionPoints == nil then
			ASECollisionPoints = {}
		end
		local p = {}
		p.x = x
		p.y = y 
		p.z = z
		table.insert( ASECollisionPoints, p )
		
		return false
		
	elseif not( other == self.vehicle
					 or self.vehicle.trafficCollisionIgnoreList[transformId]
					 or self.vehicle.trafficCollisionIgnoreList[parent]
					 or self.vehicle.trafficCollisionIgnoreList[parentParent]
					 or AutoSteeringEngine.isAttachedImplement( self.vehicle, object ) ) then
	--	print("vehicle  "..tostring(getName(transformId)))
	--	self.vehicle.aseHasCollision = true
	--	return false
	end

	return true	
end


------------------------------------------------------------------------
-- AutoSteeringEngineCallback:overlap
------------------------------------------------------------------------
function AutoSteeringEngineCallback:overlap( transformId )

	local parent = getParent(transformId)
	
	if     transformId         == g_currentMission.terrainRootNode 
			or parent              == g_currentMission.terrainRootNode then
		return true
	end

	local parentParent = getParent(parent)	
	local other = g_currentMission.nodeToVehicle[transformId]
	if other == nil then
		other = g_currentMission.nodeToVehicle[parent]
	end
	if other == nil then
		other = g_currentMission.nodeToVehicle[parentParent]
	end			
	
	if     other == nil 
			or not( other == self.vehicle
					 or self.vehicle.trafficCollisionIgnoreList[transformId]
					 or self.vehicle.trafficCollisionIgnoreList[parent]
					 or self.vehicle.trafficCollisionIgnoreList[parentParent]
					 or AutoSteeringEngine.isAttachedImplement( self.vehicle, object ) ) then
		self.vehicle.aseHasCollision = true
		return false
	end

	return true	
end


------------------------------------------------------------------------
-- hasCollisionHelper
------------------------------------------------------------------------
function AutoSteeringEngine.hasCollisionHelper( vehicle, wx, wz, dx, dz, l, doBreak )
	if boBreak and vehicle.aseHasCollision then
		return
	end
	
	if     not AutoSteeringEngine.checkField( vehicle, wx + l * dx, wz + l * dz )
			or not AutoSteeringEngine.checkField( vehicle, wx , wz )then										
		local wy = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, wx, 1, wz) 
		local dy = ( getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, wx + l * dx, 1, wz + l * dz) - wy ) / l
		local hasCollision = vehicle.aseHasCollision
		vehicle.aseHasCollision = false
		for y=0.5,1.5,ASEGlobals.colliStep do					
			if vehicle.aseHasCollision then
				break
			end
			raycastAll(wx, wy + y, wz, dx, dy, dz, "raycast", l, vehicle.aseCallback )--, nil, ASEGlobals.colliMask )
		end
		if hasCollision then
			vehicle.aseHasCollision = true
		end
	end
end

------------------------------------------------------------------------
-- hasCollision
------------------------------------------------------------------------
function AutoSteeringEngine.hasCollision( vehicle, nodeId )
	if vehicle.aseCollision < 1 then return false end
	if ASEGlobals.colliMask <= 0 then return false end
	if vehicle.aseChain == nil or vehicle.aseChain.headlandNode == nil then return false end
	if nodeId == nil then nodeId = vehicle.aseChain.headlandNode end
	
	if vehicle.aseCollisions == nil then
		vehicle.aseCollisions = {}
	end
	
	if vehicle.aseCollisions[nodeId] == nil then
		if vehicle.aseCallback == nil then
			vehicle.aseCallback = AutoSteeringEngineCallback.create( vehicle )
		end
		vehicle.aseHasCollision = false
	
		if     not AutoSteeringEngine.isFieldAhead( vehicle,  vehicle.aseCollision, nodeId )
				or not AutoSteeringEngine.isFieldAhead( vehicle, -vehicle.aseCollision, nodeId ) then
			local r0 = 1.5
			if vehicle.aseChain.radius ~= nil then
				r0 = math.max( r0, vehicle.aseChain.radius )
			end
			if     vehicle.aseTurnMode == "A"
					or vehicle.aseTurnMode == "L" then
				r0 = r0 + math.max( 3, Utils.getNoNil( vehicle.aseChain.wheelBase, 0 ) + 2 )
			end
			if ( vehicle.aseChain ~= nil and vehicle.aseLRSwitch ~= nil and vehicle.aseToolCount ~= nil and vehicle.aseToolCount >= 1 ) then
				for _,tool in pairs(vehicle.aseTools) do
					r0 = math.max( r0, math.max( tool.xl, tool.xr ) )
				end
			end
			
			local wx, wy, wz = getWorldTranslation( nodeId )
			
			local cx1, cx2, cz1, cz2
			
			if ASECollisionPoints ~= nil and table.getn( ASECollisionPoints ) > 0 then
				local cl = Utils.vector2LengthSq( r0, vehicle.aseCollision )
			
				for _,p in pairs( ASECollisionPoints ) do
					--print("x: "..tostring(wx).." z: "..tostring(wz).." p.x: "..tostring(p.x).." p.z: "..tostring(p.z))
					if Utils.vector2LengthSq( wx - p.x, wz - p.z ) <= cl then
						local lx, ly, lz = worldToLocal( nodeId, wx, wy, wz )
						local ax
						if     lx > 1.5 then
							ax = lx							
						elseif lx < -1.5 then
							ax = -lx
						else
							ax = 0
						end						
						local az = math.abs( lz )
						--print("ax: "..tostring(ax).." az: "..tostring(az))
						if ax < 1 and az < 1 then
							--print("found static 1")
							vehicle.aseHasCollision = true
							break
						elseif  az <= vehicle.aseCollision 
						    and ( ax < 1E-3 or ax <= az * r0 / vehicle.aseCollision ) then
							--print("found static 2")
							vehicle.aseHasCollision = true
							break
						end
					end
				end
			end
			
			if not vehicle.aseHasCollision then
				--local maxCl = Utils.vector2Length( r0 + 1.5, vehicle.aseCollision )
				-- left & right
				for f=0,1,ASEGlobals.colliStep do
					local r          = f * r0 
					local cl         = math.sqrt( r * r + vehicle.aseCollision * vehicle.aseCollision )
					cx1,_,cz1  = localDirectionToWorld( vehicle.aseChain.headlandNode, r / cl, 0, vehicle.aseCollision / cl )
					cx2,_,cz2  = localDirectionToWorld( vehicle.aseChain.headlandNode,-r / cl, 0, vehicle.aseCollision / cl )
					--cl = math.min( cl, maxCl )
													
					AutoSteeringEngine.hasCollisionHelper( vehicle, wx, wz, cx1, cz1, cl )
					AutoSteeringEngine.hasCollisionHelper( vehicle, wx, wz,-cx1,-cz1, cl )
					AutoSteeringEngine.hasCollisionHelper( vehicle, wx, wz, cx2, cz2, cl )
					AutoSteeringEngine.hasCollisionHelper( vehicle, wx, wz,-cx2,-cz2, cl )					
				end

				-- the T (front & back)
				cx1,_,cz1  = localDirectionToWorld( vehicle.aseChain.headlandNode, 1, 0, 0 )
				cx2,_,cz2  = localDirectionToWorld( vehicle.aseChain.headlandNode, 0, 0, 1 )
				for z=-3,0,ASEGlobals.colliStep do
					local vx, vz
					vx = wx + ( z + vehicle.aseCollision ) * cx2 - r0 * cx1
					vz = wz + ( z + vehicle.aseCollision ) * cz2 - r0 * cz1 					
					AutoSteeringEngine.hasCollisionHelper( vehicle, vx, vz, cx1, cz1, r0 + r0 )
					vx = wx - ( z + vehicle.aseCollision ) * cx2 - r0 * cx1                   
					vz = wz - ( z + vehicle.aseCollision ) * cz2 - r0 * cz1                   
					AutoSteeringEngine.hasCollisionHelper( vehicle, vx, vz, cx1, cz1, r0 + r0 )
				end
				
				-- the middle (vehicle width)
				for x=-1.5,1.5,ASEGlobals.colliStep do
					vx = wx + x * cx1
					vz = wz + x * cz1 																
					AutoSteeringEngine.hasCollisionHelper( vehicle, vx, vz, cx2, cz2, vehicle.aseCollision )
					AutoSteeringEngine.hasCollisionHelper( vehicle, vx, vz,-cx2,-cz2, vehicle.aseCollision )
				end
			end
		end
		
		vehicle.aseCollisions[nodeId] = vehicle.aseHasCollision
	end
	
	return vehicle.aseCollisions[nodeId]
end

------------------------------------------------------------------------
-- isAttachedImplement
------------------------------------------------------------------------
function AutoSteeringEngine.isAttachedImplement( vehicle, object )
	if vehicle == nil or object == nil then
		return false
	end
	if vehicle == object then
		return true
	end
	if vehicle.attachedImplements == nil then
		return false
	end	
	for _, implement in pairs(vehicle.attachedImplements) do
		if AutoSteeringEngine.isAttachedImplement( implement.object, object ) then
			return true
		end
	end		
	return false
end

------------------------------------------------------------------------
-- hasFruits
------------------------------------------------------------------------
function AutoSteeringEngine.hasFruits( vehicle, widthFactor )

	if not vehicle.isServer then return false end
	
	if AutoSteeringEngine.hasCollision( vehicle ) then return false end

	if widthFactor == nil then widthFactor = 1 end
	
	local fruitsDetected = false
	local fruitsAll      = true
	vehicle.aseFruitAreas = {}
	
	if  ( vehicle.aseChain ~= nil and vehicle.aseLRSwitch ~= nil and vehicle.aseToolCount ~= nil and vehicle.aseToolCount >= 1 ) and vehicle.aseToolParams ~= nil and table.getn( vehicle.aseToolParams ) == vehicle.aseToolCount then
		for i = 1,vehicle.aseToolCount do	
			vehicle.aseToolParams[i].hasFruits = false
			local tool      = vehicle.aseTools[vehicle.aseToolParams[i].i]
			local gotFruits = false
			local back      = -1
			local front     = 2
			
			back  = math.min( vehicle.aseToolParams[i].zBack - vehicle.aseToolParams[i].zReal +back, back )
			front = math.max( vehicle.aseToolParams[i].zBack - vehicle.aseToolParams[i].zReal +front, front )
			
			local dx,dz
			if tool.steeringAxleNode == nil then
				dx,_,dz = localDirectionToWorld( vehicle.aseChain.refNode, 0, 0, 1 )
			elseif tool.invert then
				dx,_,dz = localDirectionToWorld( tool.steeringAxleNode, 0, 0, -1 )
			else
				dx,_,dz = localDirectionToWorld( tool.steeringAxleNode, 0, 0, 1 )
			end
			
			local cx,cz = AutoSteeringEngine.getChainPoint( vehicle, 1, vehicle.aseToolParams[i] )
			local xw2,y,zw2 = localToWorld( vehicle.aseChain.refNode, cx, 0, cz + front )
			local xw1 = xw2 + ( back - front ) * dx
			local zw1 = zw2 + ( back - front ) * dz
			
			local w = widthFactor * vehicle.aseToolParams[i].width
			if vehicle.aseLRSwitch then
				w = -w
			end
			
			local lx1,lz1,lx2,lz2,lx3,lz3,lx4,lz4
			dist = front - back
			repeat 
				xw2 = xw1 + dist * dx
				zw2 = zw1 + dist * dz
				lx1,lz1,lx2,lz2,lx3,lz3 = AutoSteeringEngine.getParallelogram( xw1,zw1,xw2,zw2, w, true )
				lx4 = lx3 + lx2 - lx1
				lz4 = lz3 + lz2 - lz1
				
				dist = dist - 0.5
			until dist < 0.5
					or ( vehicle.aseHeadland >= 1
					 and ( AutoSteeringEngine.isChainPointOnField( vehicle, lx3, lz3 )
 						  or AutoSteeringEngine.isChainPointOnField( vehicle, lx4, lz4 )
	 						or AutoSteeringEngine.isChainPointOnField( vehicle, 0.5 * ( lx3 + lx4), 0.5 * ( lz3 + lz4 ) ) ) )
					or ( vehicle.aseHeadland < 1
					 and ( AutoSteeringEngine.checkField( vehicle, lx3, lz3 )
					    or AutoSteeringEngine.checkField( vehicle, lx4, lz4 )
					    or AutoSteeringEngine.checkField( vehicle, 0.5 * ( lx3 + lx4), 0.5 * ( lz3 + lz4 ) ) ) )

			local lx5 = 0.25 * ( lx1 + lx2 + lx3 + lx4 )
			local lz5 = 0.25 * ( lz1 + lz2 + lz3 + lz4 )
			
			if vehicle.aseHeadland < 1 then
				if     ( AutoSteeringEngine.checkField( vehicle, lx1, lz1 )
							or AutoSteeringEngine.checkField( vehicle, lx2, lz2 )
							or AutoSteeringEngine.checkField( vehicle, lx3, lz3 )
							or AutoSteeringEngine.checkField( vehicle, lx4, lz4 )
							or AutoSteeringEngine.checkField( vehicle, lx5, lz5 ) )
						and AutoSteeringEngine.getFruitArea( vehicle, xw1,zw1,xw2,zw2, w, vehicle.aseToolParams[i].i, true ) > 0 then
					gotFruits = true
				end			
			else
				if     ( AutoSteeringEngine.isChainPointOnField( vehicle, lx1, lz1 )
							or AutoSteeringEngine.isChainPointOnField( vehicle, lx2, lz2 )
							or AutoSteeringEngine.isChainPointOnField( vehicle, lx3, lz3 )
							or AutoSteeringEngine.isChainPointOnField( vehicle, lx4, lz4 )
							or AutoSteeringEngine.isChainPointOnField( vehicle, lx5, lz5 ) )
						and AutoSteeringEngine.getFruitArea( vehicle, xw1,zw1,xw2,zw2, w, vehicle.aseToolParams[i].i, true ) > 0 then
					gotFruits = true
				end			
			end			
			
			vehicle.aseFruitAreas[i] = { lx1, lz1, lx2, lz2, lx3, lz3, lx4, lz4, gotFruits }

      if not gotFruits then 
				if     tool.ignoreAI then
				-- ignore 
				else
					fruitsAll = false
				end
			end
			
			if gotFruits then
				vehicle.aseToolParams[i].hasFruits = true
				if     tool.ignoreAI then
				-- ignore 
				else
					fruitsDetected = true				
				end
			elseif tool.lowerStateOnFruits and ASEGlobals.lowerAdvance > 0 then
				-- lower tool in advance
				
				xw1 = xw1 + ASEGlobals.lowerAdvance * dx
				zw1 = zw1 + ASEGlobals.lowerAdvance * dz
				dist = front - back
				repeat 
					xw2 = xw1 + dist * dx
					zw2 = zw1 + dist * dz
					lx1,lz1,lx2,lz2,lx3,lz3 = AutoSteeringEngine.getParallelogram( xw1,zw1,xw2,zw2, w, true )
					lx4 = lx3 + lx2 - lx1
					lz4 = lz3 + lz2 - lz1
					
					dist = dist - 0.5
				until dist < 0.5
						or ( vehicle.aseHeadland >= 1
						 and ( AutoSteeringEngine.isChainPointOnField( vehicle, lx3, lz3 )
								or AutoSteeringEngine.isChainPointOnField( vehicle, lx4, lz4 )
								or AutoSteeringEngine.isChainPointOnField( vehicle, 0.5 * ( lx3 + lx4), 0.5 * ( lz3 + lz4 ) ) ) )
						or ( vehicle.aseHeadland < 1
						 and ( AutoSteeringEngine.checkField( vehicle, lx3, lz3 )
								or AutoSteeringEngine.checkField( vehicle, lx4, lz4 )
								or AutoSteeringEngine.checkField( vehicle, 0.5 * ( lx3 + lx4), 0.5 * ( lz3 + lz4 ) ) ) )

				if vehicle.aseHeadland < 1 then
					if     ( AutoSteeringEngine.checkField( vehicle, lx1, lz1 )
								or AutoSteeringEngine.checkField( vehicle, lx2, lz2 )
								or AutoSteeringEngine.checkField( vehicle, lx3, lz3 )
								or AutoSteeringEngine.checkField( vehicle, lx4, lz4 ) )
							and AutoSteeringEngine.getFruitArea( vehicle, xw1,zw1,xw2,zw2, w, vehicle.aseToolParams[i].i, true ) > 0 then
						gotFruits = true
					end			
				else
					if     ( AutoSteeringEngine.isChainPointOnField( vehicle, lx1, lz1 )
								or AutoSteeringEngine.isChainPointOnField( vehicle, lx2, lz2 )
								or AutoSteeringEngine.isChainPointOnField( vehicle, lx3, lz3 )
								or AutoSteeringEngine.isChainPointOnField( vehicle, lx4, lz4 ) )
							and AutoSteeringEngine.getFruitArea( vehicle, xw1,zw1,xw2,zw2, w, vehicle.aseToolParams[i].i, true ) > 0 then
						gotFruits = true
					end			
				end		
				
			--vehicle.aseFruitAreas[i] = { lx1, lz1, lx2, lz2, lx3, lz3, lx4, lz4, gotFruits }
			elseif  ASEGlobals.raiseNoFruits > 0
					and vehicle.acTurnStage == 0
					and ( tool.isSowingMachine
						 or tool.isCultivator
						 or tool.isSprayer
						 or tool.isMower 
						 or tool.isTedder   
						 or tool.isWindrower ) then
				AutoSteeringEngine.raiseToolNoFruits( vehicle, tool.obj )
			end

			AutoSteeringEngine.ensureToolIsLowered( vehicle, gotFruits, i )
		end
	end
	
	return fruitsDetected, fruitsAll
end

------------------------------------------------------------------------
-- hasFruitsSimple
------------------------------------------------------------------------
function AutoSteeringEngine.hasFruitsSimple( vehicle, xw1, zw1, xw2, zw2, off )
	for i=1,vehicle.aseToolCount do
		if AutoSteeringEngine.getFruitArea( vehicle, xw1,zw1,xw2,zw2, off, i, true ) > 0 then
			return true
		end
	end
	return false
end

------------------------------------------------------------------------
-- noTurnAtEnd
------------------------------------------------------------------------
function AutoSteeringEngine.noTurnAtEnd( vehicle )

	--local noTurn = false
	--if ( vehicle.aseChain ~= nil and vehicle.aseLRSwitch ~= nil and vehicle.aseToolCount ~= nil and vehicle.aseToolCount >= 1 ) then
	--	for i=1,vehicle.aseToolCount do
  --    if vehicle.aseTools[i].isPlough or vehicle.aseTools[i].isSprayer or vehicle.aseTools[i].specialType == "Packomat" or vehicle.aseTools[i].doubleJoint
	--			then noTurn = true end
	--	end
	--end
	--
	--return noTurn
	
	if      ( vehicle.aseChain ~= nil and vehicle.aseLRSwitch ~= nil and vehicle.aseToolCount ~= nil and vehicle.aseToolCount >= 1 )
			and ( vehicle.aseHas.plough or vehicle.aseHas.sprayer or vehicle.aseHas.doubleJoint ) then 
		return true 
	end
	return false 
end

------------------------------------------------------------------------
-- getNoReverseIndex
------------------------------------------------------------------------
function AutoSteeringEngine.getNoReverseIndex( vehicle )

	return Utils.getNoNil( vehicle.aseNoReverseIndex, 0 )

	--local noReverseIndex = 0
	--
	--if ( vehicle.aseChain ~= nil and vehicle.aseLRSwitch ~= nil and vehicle.aseToolCount ~= nil and vehicle.aseToolCount >= 1 ) then
	--	for i=1,vehicle.aseToolCount do
	--		if vehicle.aseTools[i].aiForceTurnNoBackward and vehicle.aseTools[i].steeringAxleNode ~= nil then
	--			noReverseIndex = i
	--		end
	--	end
	--end
	--
	--return noReverseIndex
end

------------------------------------------------------------------------
-- getTurnMode
------------------------------------------------------------------------
function AutoSteeringEngine.getTurnMode( vehicle )
	local revUTurn   = true
	local revStraight= true
	local smallUTurn = true
	local zb         = nil
	local noHire     = false
	
	if ( vehicle.aseChain ~= nil and vehicle.aseLRSwitch ~= nil and vehicle.aseToolCount ~= nil and vehicle.aseToolCount >= 1 ) then
		for i=1,vehicle.aseToolCount do
--		local _,_,z = AutoSteeringEngine.getRelativeTranslation( vehicle.aseChain.refNode, vehicle.aseTools[i].refNode ) 
--		z = z + 0.5 * ( vehicle.aseTools[i].zb + vehicle.aseTools[i].z )
--		--print(tostring(zb).." "..tostring(z))
--		if      zb == nil then
--			zb = z
--		elseif  math.abs( z - zb ) > 2
--		    and ( zb > 0 and z < 0
--		       or zb < 0 and z > 0 ) then
--			smallUTurn = false
--		end
			
			if vehicle.aseTools[i].noRevStraight then
				revStraight= false
			end
			if      vehicle.aseTools[i].aiForceTurnNoBackward 
					and vehicle.aseTools[i].steeringAxleNode ~= nil then
				revUTurn   = false
				smallUTurn = false
--			elseif  vehicle.aseTools[i].isSprayer then
--				revUTurn   = false
--				smallUTurn = false
--				break
--		elseif  vehicle.aseTools[i].isCombine 
--				or  vehicle.aseTools[i].isMower then
--			smallUTurn = false
			end
			
--		if vehicle.aseTools[i].isSprayer then
--			noHire = true
--		end
		end
	end
	
	if not revStraight then
		revUTurn   = false
		smallUTurn = false
	end
	
	return smallUTurn, revUTurn, revStraight, noHire
end
		

------------------------------------------------------------------------
-- getToolAngle
------------------------------------------------------------------------
function AutoSteeringEngine.getToolAngle( vehicle )

	local toolAngle = 0
	local i         = AutoSteeringEngine.getNoReverseIndex( vehicle )
	
	if i>0 then	
		if vehicle.aseTools[i].checkZRotation then
			local zAngle = AutoSteeringEngine.getRelativeZRotation( vehicle.aseChain.refNode, vehicle.aseTools[i].steeringAxleNode )
			if math.abs( zAngle ) > 0.025 then
				local rx2, ry2, rz2 = getRotation( vehicle.aseTools[i].steeringAxleNode )
				setRotation( vehicle.aseTools[i].steeringAxleNode, rx2, ry2, rz2 -zAngle )
			--local test = AutoSteeringEngine.getRelativeZRotation( vehicle.aseChain.refNode, vehicle.aseTools[i].steeringAxleNode )
			end
		end
		--toolAngle = AutoSteeringEngine.getRelativeYRotation( vehicle.steeringAxleNode, vehicle.aseTools[i].steeringAxleNode )	
		toolAngle = AutoSteeringEngine.getRelativeYRotation( vehicle.aseChain.refNode, vehicle.aseTools[i].steeringAxleNode )	
		
		if vehicle.aseTools[i].offsetZRotation ~= nil then
			toolAngle = toolAngle + vehicle.aseTools[i].offsetZRotation
		end
		
		if vehicle.aseTools[i].invert then
			if toolAngle < 0 then
				toolAngle = toolAngle + math.pi
			else
				toolAngle = toolAngle - math.pi
			end
		end
	end
	
	return toolAngle
end

------------------------------------------------------------------------
-- getAngleFactor
------------------------------------------------------------------------
function AutoSteeringEngine.getAngleFactor( maxLooking )
	return Utils.clamp( Utils.getNoNil( maxLooking, ASEGlobals.maxLooking ) / ASEGlobals.maxLooking, 0.1, 1 ) * ASEGlobals.angleStep	
end

------------------------------------------------------------------------
-- isSetAngleZero
------------------------------------------------------------------------
function AutoSteeringEngine.isSetAngleZero( vehicle )
	if ASEGlobals.zeroAngle > 0 then
		return true
	end
	if vehicle.acTurnStage ~= nil and vehicle.acTurnStage > 0 then
		return true
	end
	return false
end

------------------------------------------------------------------------
-- setSteeringAngle
------------------------------------------------------------------------
function AutoSteeringEngine.setSteeringAngle( vehicle, angle )
	if AutoSteeringEngine.isSetAngleZero( vehicle ) then
		vehicle.aseSteeringAngle = 0
	elseif vehicle.aseSteeringAngle == nil or math.abs( vehicle.aseSteeringAngle - angle ) > 1E-3 then
		AutoSteeringEngine.setChainStatus( vehicle, 1, ASEStatus.initial )
		vehicle.aseSteeringAngle = angle
	end 
	if vehicle.aseMinAngle == nil or vehicle.aseMaxAngle == nil then
		vehicle.aseSteeringAngle = angle
	else
		vehicle.aseSteeringAngle = math.min( math.max( angle, vehicle.aseMinAngle ), vehicle.aseMaxAngle )
	end
end

------------------------------------------------------------------------
-- currentSteeringAngle
------------------------------------------------------------------------
function AutoSteeringEngine.currentSteeringAngle( vehicle, isInverted )
	local steeringAngle = 0		

	if      vehicle.articulatedAxis ~= nil 
			and vehicle.articulatedAxis.componentJoint ~= nil
			and vehicle.articulatedAxis.componentJoint.jointNode ~= nil then
		steeringAngle = 0.5 * math.min( math.max( -vehicle.rotatedTime * vehicle.articulatedAxis.rotSpeed, vehicle.articulatedAxis.rotMin ), vehicle.articulatedAxis.rotMax )
	else
		for _,wheel in pairs(vehicle.wheels) do
			if math.abs(wheel.rotSpeed) > 1E-3 then
				if math.abs( wheel.steeringAngle ) > math.abs( steeringAngle ) then
					if wheel.rotSpeed > 0 then
						steeringAngle = wheel.steeringAngle
					else
						steeringAngle = -wheel.steeringAngle
					end
				end
			end
		end
	end	
	
	--if isInverted or ( isInverted == nil and vehicle.aseChain ~= nil and vehicle.aseChain.isInverted ) then
	--	steeringAngle = -steeringAngle
	--end

	vehicle.aseRealSteeringAngle = steeringAngle 
	
	if vehicle.aseSteeringAngle ~= nil and 0 < ASEGlobals.average and ASEGlobals.average < 1 then
		steeringAngle = ASEGlobals.average * steeringAngle + (1-ASEGlobals.average) * vehicle.aseSteeringAngle
	end
	
	--local neg = false
	--if steeringAngle < 0 then neg = true end
	--
	--local f = math.rad(3)
	--
	--steeringAngle = f * math.floor( math.abs( steeringAngle / f ) + 0.5 )
	--if neg then steeringAngle = -steeringAngle end
	
	if AutoSteeringEngine.isSetAngleZero( vehicle ) then
		AutoSteeringEngine.setSteeringAngle( vehicle, 0 )
	else
		AutoSteeringEngine.setSteeringAngle( vehicle, steeringAngle )
	end
	
	return steeringAngle
end

------------------------------------------------------------------------
-- steer
------------------------------------------------------------------------
function AutoSteeringEngine.steer( vehicle, ... )
	vehicle.aseSteerParameteters = { ... }
	AutoSteeringEngine.steerDirect( vehicle, ... )
end
function AutoSteeringEngine.steerContinued( vehicle )
	if vehicle.aseSteerParameteters ~= nil then
		AutoSteeringEngine.steerDirect( vehicle, unpack( vehicle.aseSteerParameteters ) )
	end
end
function AutoSteeringEngine.steerDirect( vehicle, dt, angle, aiSteeringSpeed, directSteer )
-- precondition: vehicle.rotatedTime is filled from last steering
	if vehicle.aseChain.isInverted then
		angle = -angle
	end
	if vehicle.isReverseDriving then
		angle = -angle
	end

	if     angle == 0 then
		targetRotTime = 0
	elseif angle  > 0 then
		targetRotTime = vehicle.maxRotTime * math.min( angle / vehicle.aseChain.maxSteering, 1)
	else
		targetRotTime = vehicle.minRotTime * math.min(-angle / vehicle.aseChain.maxSteering, 1)
	end
	
	local aiDirectSteering = 1
	if vehicle.articulatedAxis == nil then
		if directSteer then
			aiDirectSteering = ASEGlobals.aiSteeringD
		else
			aiDirectSteering = ASEGlobals.aiSteering
		end
	else
		if directSteer then
			aiDirectSteering = ASEGlobals.artSteeringD
		else
			aiDirectSteering = ASEGlobals.artSteering
		end
	end
	
	local diff = dt * aiSteeringSpeed
	if aiDirectSteering <= 0 then
		diff = math.min( diff+diff+diff+diff+diff+diff, math.abs( math.min( 1, -aiDirectSteering ) * ( targetRotTime - vehicle.rotatedTime ) ) )
	else
		diff = aiDirectSteering * diff
	end
	
	if targetRotTime > vehicle.rotatedTime then
		vehicle.rotatedTime = math.min(vehicle.rotatedTime + diff, targetRotTime)
	else
		vehicle.rotatedTime = math.max(vehicle.rotatedTime - diff, targetRotTime)
	end
	
	if AutoSteeringEngine.isSetAngleZero( vehicle ) then
		vehicle.aseSteeringAngle = 0
	elseif vehicle.aseSteeringAngle == nil or math.abs( vehicle.aseSteeringAngle - angle ) > 1E-3 then
		AutoSteeringEngine.setChainStatus( vehicle, 1, ASEStatus.initial )
		vehicle.aseSteeringAngle = angle
	end 
end

------------------------------------------------------------------------
-- drive
------------------------------------------------------------------------
function AutoSteeringEngine.drive( vehicle, ... )
	vehicle.aseDriveParameteters = { ... }
	AutoSteeringEngine.driveDirect( vehicle, ... )
end
function AutoSteeringEngine.driveContinued( vehicle )
	if vehicle.aseDriveParameteters ~= nil then
		AutoSteeringEngine.driveDirect( vehicle, unpack( vehicle.aseDriveParameteters ) )
	end
end
function AutoSteeringEngine.driveDirect( vehicle, dt, acceleration, allowedToDrive, moveForwards, speedLevel, useReduceSpeed, slowMaxRpmFactor )

	if moveForwards ~= nil then
		if vehicle.aseChain.isInverted then
			moveForwards = not moveForwards
		end
		if vehicle.isReverseDriving then
			moveForwards = not moveForwards
		end
	end
	
	
  if vehicle.firstTimeRun then
    local acc = acceleration
		local disableChangingDirection = false
		local doHandBrake = false

		local wantedSpeed = AutoSteeringEngine.getWantedSpeed( vehicle, speedLevel )
    if useReduceSpeed then
      acc         = acc * slowMaxRpmFactor
			wantedSpeed = wantedSpeed * slowMaxRpmFactor
    end
		
    if not moveForwards then
      acc = -acc
    end
		
    if not allowedToDrive then
      acc = 0
		end
			
		if vehicle.acLastAcc == nil then
			vehicle.acLastAcc = 0
		end
		if vehicle.acLastWantedSpeed == nil then
			vehicle.acLastWantedSpeed = 2
		end
			
		if     math.abs( acc ) < 1E-4
				or ( acc > 0 and vehicle.acLastAcc < 0 )
				or ( acc < 0 and vehicle.acLastAcc > 0 ) then
			vehicle.acLastAcc = 0
			wantedSpeed       = 0
			vehicle.acLastWantedSpeed = 0
		else
			vehicle.acLastAcc = vehicle.acLastAcc + Utils.clamp( acc - vehicle.acLastAcc, - dt * 0.0005, dt * 0.0005)
		end
				
		if     wantedSpeed < 2 then
			allowedToDrive            = false
			vehicle.acLastWantedSpeed = 2
		elseif wantedSpeed < 5 then
			vehicle.acLastWantedSpeed = wantedSpeed
		else
			vehicle.acLastWantedSpeed = vehicle.acLastWantedSpeed + Utils.clamp( wantedSpeed - vehicle.acLastWantedSpeed, -0.0015 * dt, 0.0015 * dt )
		end
		vehicle.motor:setSpeedLimit( vehicle.acLastWantedSpeed )
		
		WheelsUtil.updateWheelsPhysics(vehicle, dt, vehicle.lastSpeed, vehicle.acLastAcc, not allowedToDrive, vehicle.requiredDriveMode)
  end
	
	
	if vehicle.aseCurrentWorkArea ~= nil and allowedToDrive and vehicle.acTurnStage <= 0 and vehicle.aseToolParams ~= nil then
		for _,tp in pairs( vehicle.aseToolParams ) do
			local lx1,_,lz1 = getWorldTranslation( tp.nodeLeft )
			local lx2,_,lz2 = getWorldTranslation( tp.nodeRight )
			
			local dx, dz = localDirectionToWorld( vehicle.aseChain.refNode, 0, 0, - 1 )
			local lx3 = lx1 + dx
			local lz3 = lz1 + dz
			
			vehicle.aseCurrentWorkArea.cutArea( lx1,lz1,lx2,lz2,lx3,lz3 )
		end
	end
end

------------------------------------------------------------------------
-- drawMarker
------------------------------------------------------------------------
function AutoSteeringEngine.drawMarker( vehicle )

	if not vehicle.isServer then return end
	
	if vehicle.debugRendering then
		AutoSteeringEngine.displayDebugInfo( vehicle )
	end

	if vehicle.aseHeadland > 0 and vehicle.aseWidth ~= nil then		
		AutoSteeringEngine.rotateHeadlandNode( vehicle )
		local w = math.max( 1, 0.25 * vehicle.aseWidth )--+ 0.13 * vehicle.aseHeadland )		
		local x1,y1,z1 = localToWorld( vehicle.aseChain.headlandNode, -2 * w, 1, vehicle.aseHeadland )
		local x2,y2,z2 = localToWorld( vehicle.aseChain.headlandNode,  2 * w, 1, vehicle.aseHeadland )
		y1 = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x1, 1, z1) + 1
		y2 = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x2, 1, z2) + 1
		drawDebugLine( x1,y1,z1, 1,1,0, x2,y2,z2, 1,1,0 )
	end
	--if vehicle.aseCollisionPoints ~= nil and table.getn( vehicle.aseCollisionPoints ) > 0 then
	--	for _,p in pairs(vehicle.aseCollisionPoints) do
	--		local y = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, p.x, 1, p.z)
	--		drawDebugLine(  p.x,y,p.z, 1,0,0, p.x,y+2,p.z, 1,0,0 )
	--		drawDebugPoint( p.x,y+2,p.z, 1, 1, 1, 1 )
	--	end
	--end
	
	if vehicle.aseToolParams ~= nil and table.getn( vehicle.aseToolParams ) > 0 then
		local px,py,pz
		local off = 1
		if not vehicle.aseLRSwitch then
			off = -off
		end
					
		for j=1,table.getn(vehicle.aseToolParams) do
			local tp = vehicle.aseToolParams[j]
			
		--for _,m in pairs(vehicle.aseTools[tp.i].marker) do
		--	local x,y,z = getWorldTranslation( m )
		--	y = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x, 1, z)
		--	drawDebugLine(  x,y,z, 0,0,1, x,y+2,z, 0,0,1 )
		--	drawDebugPoint( x,y+2,z, 1, 1, 1, 1 )
		--end
		--
		--if vehicle.aseTools[tp.i].aiBackMarker ~= nil then
		--	local x,y,z = getWorldTranslation( vehicle.aseTools[tp.i].aiBackMarker )
		--	y = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x, 1, z)
		--	drawDebugLine(  x,y,z, 0,1,0, x,y+2,z, 0,1,0 )
		--	drawDebugPoint( x,y+2,z	, 1, 1, 1, 1 )
		--end
			
			if not ( tp.skip ) and vehicle.acIamDetecting then
				local c = { 0.5, 0.5, 0.5 }
				if      tp.noEmptyBorder then
					c = { 1, 0, 0 }
				elseif  vehicle.aseFruitAreas ~= nil 
						and vehicle.aseFruitAreas[j] ~= nil 
						and vehicle.aseFruitAreas[j][9] then
					c = { 0, 1, 0 }
				end
				local x, z = AutoSteeringEngine.getChainPoint( vehicle, 2, tp )
				local wx,wy,wz = localToWorld( vehicle.aseChain.nodes[2].index ,x, 1, z )
				x, z = AutoSteeringEngine.getChainPoint( vehicle, 3, tp )
				local x2,y2,z2 = localToWorld( vehicle.aseChain.nodes[3].index ,x, 1, z )
				x2 = 0.5*( wx+x2 )
				z2 = 0.5*( wz+z2 )
				--x, z = AutoSteeringEngine.getChainPoint( vehicle, 1, tp )
				--wx,wy,wz = localToWorld( vehicle.aseChain.nodes[1].index ,x, 1, z )
				wx,_,wz = localToWorld( vehicle.aseChain.refNode, tp.x, 0, tp.z )
				wy = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, wx, 1, wz )
				y2 = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x2, 1, z2 )
				drawDebugLine(  wx,wy    ,wz, c[1],c[2],c[3], wx,wy+1.2,wz, c[1],c[2],c[3] )
				drawDebugLine(  wx,wy+0.1,wz, c[1],c[2],c[3], x2,y2+0.1,z2, c[1],c[2],c[3] )
				drawDebugLine(  wx,wy+0.2,wz, c[1],c[2],c[3], x2,y2+0.2,z2, c[1],c[2],c[3] )
				drawDebugLine(  wx,wy+0.3,wz, c[1],c[2],c[3], x2,y2+0.3,z2, c[1],c[2],c[3] )
				drawDebugPoint( wx,wy+1.2,wz	, 1, 1, 1, 1 )
			end
		end
	end	
end
	
------------------------------------------------------------------------
-- drawLines
------------------------------------------------------------------------
function AutoSteeringEngine.drawLines( vehicle )

	if not vehicle.isServer then return end
	
	if vehicle.debugRendering then
		AutoSteeringEngine.displayDebugInfo( vehicle )
	end

	local x,_,z = AutoSteeringEngine.getAiWorldPosition( vehicle )
	local y = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x, 1, z)
	drawDebugLine(  x, y, z,0,1,0, x, y+4, z,0,1,0)
	drawDebugPoint( x, y+4, z	, 1, 1, 1, 1 )
	local x1,_,z1 = localToWorld( vehicle.aseChain.refNode ,0,0,2 )
	drawDebugLine(  x1, y+3, z1,0,1,0, x, y+3, z,0,1,0)
	
	if      vehicle.aseDirectionBeforeTurn   ~= nil 
			and vehicle.acTurnStage              ~= nil
			and vehicle.acTurnStage              ~= 0
			and vehicle.acTurnStage               < 97 then
			
		if vehicle.aseDirectionBeforeTurn.itv1 ~= nil then
			local lx1,lz1,lx2,lz2,lx3,lz3 = unpack( vehicle.aseDirectionBeforeTurn.itv1 )
			drawDebugLine(lx1,y+0.5,lz1,0,1,0,lx3,y+0.5,lz3,0,1,0)
			drawDebugLine(lx1,y+0.5,lz1,0,1,0,lx2,y+0.5,lz2,0,1,0)
		--local lx4 = lx3 + lx2 - lx1
		--local lz4 = lz3 + lz2 - lz1
		--drawDebugLine(lx4,y+0.5,lz4,0,1,1,lx2,y+0.5,lz2,0,1,1)
		--drawDebugLine(lx4,y+0.5,lz4,0,1,1,lx3,y+0.5,lz3,0,1,1)
		end
		
		if vehicle.aseDirectionBeforeTurn.itv2 ~= nil then
			local lx1,lz1,lx2,lz2,lx3,lz3 = unpack( vehicle.aseDirectionBeforeTurn.itv2 )
			drawDebugLine(lx1,y+0.5,lz1,0,0,1,lx3,y+0.5,lz3,0,0,1)
			drawDebugLine(lx1,y+0.5,lz1,0,0,1,lx2,y+0.5,lz2,0,0,1)
		--local lx4 = lx3 + lx2 - lx1
		--local lz4 = lz3 + lz2 - lz1
		--drawDebugLine(lx4,y+0.5,lz4,0,1,1,lx2,y+0.5,lz2,0,1,1)
		--drawDebugLine(lx4,y+0.5,lz4,0,1,1,lx3,y+0.5,lz3,0,1,1)
		end	
	end
	
	if      vehicle.aseDirectionBeforeTurn    ~= nil 
			and vehicle.aseDirectionBeforeTurn.ox ~= nil 
			and vehicle.aseDirectionBeforeTurn.oz ~= nil then
	
		xw1 = vehicle.aseDirectionBeforeTurn.cx
		zw1 = vehicle.aseDirectionBeforeTurn.cz
		drawDebugLine(  xw1, y, zw1, 1,0,1, xw1, y+2, zw1 ,1,1,1)
		drawDebugPoint( xw1, y+2, zw1 , 0, 1, 0, 1 )		
		
		xw1 = vehicle.aseDirectionBeforeTurn.ux
		zw1 = vehicle.aseDirectionBeforeTurn.uz
		drawDebugLine(  xw1, y, zw1, 1,0,1, xw1, y+2, zw1 ,1,1,1)
		drawDebugPoint( xw1, y+2, zw1 , 0, 0, 1, 1 )		
		
		xw1 = vehicle.aseDirectionBeforeTurn.ox
		zw1 = vehicle.aseDirectionBeforeTurn.oz
		drawDebugLine(  xw1, y, zw1, 1,0,1, xw1, y+2, zw1 ,1,1,1)
		drawDebugPoint( xw1, y+2, zw1 , 0, 0, 1, 1 )		
	end		
		
	if vehicle.aseHeadland > 0 then		
		AutoSteeringEngine.rotateHeadlandNode( vehicle )
		local w = math.max( 1, 0.25 * vehicle.aseWidth )--+ 0.13 * vehicle.aseHeadland )
		for j=-2,2 do
			local d = vehicle.aseHeadland + 1
			local x,_,z = localToWorld( vehicle.aseChain.headlandNode, j * w, 1, d )
			local y = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x, 1, z) + 1
			if AutoSteeringEngine.checkField( vehicle, x,z) then
				drawDebugPoint( x,y,z	, 0, 1, 0, 1 )
			else
				drawDebugPoint( x,y,z	, 1, 0, 0, 1 )
			end
			d = - vehicle.aseHeadland - 1
			x,_,z = localToWorld( vehicle.aseChain.headlandNode, j * w, 1, d )
			y = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x, 1, z) + 1
			if AutoSteeringEngine.checkField( vehicle, x,z) then
				drawDebugPoint( x,y,z	, 0, 1, 0, 1 )
			else
				drawDebugPoint( x,y,z	, 1, 0, 0, 1 )
			end
		end
	end

	if vehicle.aseToolParams ~= nil and table.getn( vehicle.aseToolParams ) > 0 then
		local px,py,pz
		local off = 1
		if not vehicle.aseLRSwitch then
			off = -off
		end
					
					
		local indexMax = ASEGlobals.chainMin
		if vehicle.aseLastIndexMax ~= nil then
			indexMax = vehicle.aseLastIndexMax
		end
		
		AutoSteeringEngine.getAllChainBorders( vehicle, ASEGlobals.chainStart, indexMax )
					
		for j=1,table.getn(vehicle.aseToolParams) do
			local tp = vehicle.aseToolParams[j]
			if      vehicle.aseTools ~= nil
					and not ( tp.skip )
					and tp.i ~= nil 
					and vehicle.aseTools[tp.i] ~= nil 
					and vehicle.aseTools[tp.i].marker ~= nil then			
				for _,m in pairs(vehicle.aseTools[tp.i].marker) do
					local xl,_,zl = AutoSteeringEngine.getRelativeTranslation( vehicle.aseChain.refNode, m )
					if Utils.vector2LengthSq( xl-tp.x, zl-tp.z ) > 0.01 then
						local x,_,z = getWorldTranslation( m )
						local y = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x, 1, z)
						drawDebugLine(  x,y,z, 0,0,1, x,y+2,z, 0,0,1 )
						drawDebugPoint( x,y+2,z, 1, 1, 1, 1 )
					end
				end
			
				if vehicle.aseTools[tp.i].aiBackMarker  ~= nil then
					local x,_,z = getWorldTranslation( vehicle.aseTools[tp.i].aiBackMarker )
					local y = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x, 1, z)
					drawDebugLine(  x,y,z, 0,1,0, x,y+2,z, 0,1,0 )
					drawDebugPoint( x,y+2,z	, 1, 1, 1, 1 )
				end
				
				if vehicle.aseTools[tp.i].aiForceTurnNoBackward then
					local x,y,z
					x,_,z = localToWorld( vehicle.aseChain.refNode, 0, 0, tp.b1 )
					y = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x, 1, z)
					drawDebugLine(  x,y,z, 0.8,0,0, x,y+2,z, 0.8,0,0 )
					drawDebugPoint( x,y+2,z	, 1, 1, 1, 1 )

					local a = -AutoSteeringEngine.getToolAngle( vehicle )					
					local l = tp.b1 + tp.b2
				--print(tostring(tp.b1).." "..tostring(tp.b2).." "..tostring(math.deg(a)))
					
					x,_,z = localToWorld( vehicle.aseChain.refNode, math.sin(a) * l, 0, math.cos(a) * l )
					y = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x, 1, z)
					drawDebugLine(  x,y,z, 1,0.2,0.2, x,y+2,z, 1,0.2,0.2 )
					drawDebugPoint( x,y+2,z	, 1, 1, 1, 1 )
					
					if tp.b3 ~= nil and math.abs( tp.b3 ) > 0.1 then
						local x3,_,z3 = localDirectionToWorld( vehicle.aseChain.refNode, math.sin(a+a) * tp.b3, 0, math.cos(a+a) * tp.b3 )
						x = x + x3
						z = z + z3
						y = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x, 1, z)
						drawDebugLine(  x,y,z, 1,1,0, x,y+2,z, 1,1,0 )
						drawDebugPoint( x,y+2,z	, 1, 1, 0, 1 )
					end
				end
				
				x,_,z = localToWorld( vehicle.aseChain.refNode, tp.x, 0, tp.z )
				y = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x, 1, z)
				drawDebugLine(  x,y,z, 1,0,0, x,y+2,z, 1,0,0 )
				drawDebugPoint( x,y+2,z	, 1, 1, 1, 1 )
				
				if vehicle.acIamDetecting or ASEGlobals.staticRoot > 0 then
					for i=1,indexMax+1 do
						local x, z     = AutoSteeringEngine.getChainPoint( vehicle, i, tp )
						local wx,wy,wz = localToWorld( vehicle.aseChain.nodes[i].index ,x, 0.5, z )
						
						if      i > 1
								and vehicle.aseChain.nodes[i-1].tool[tp.i]   ~= nil 
								and vehicle.aseChain.nodes[i-1].tool[tp.i].t ~= nil then

							local lx1,lz1,lx2,lz2,lx3,lz3 = AutoSteeringEngine.getParallelogram( px, pz, wx, wz, off )
							local y = 0.5 * ( py + wy )

							local c1, c2, c3 = 0, 0, 0
							
							if     vehicle.aseChain.nodes[i-1].tool[tp.i].t < 0 then
								c1 = 0.3
								c2 = 0.3
								c3 = 0.3
							elseif vehicle.aseChain.nodes[i-1].tool[tp.i].b > 0 then
								c1 = 1
							elseif vehicle.aseChain.nodes[i-1].tool[tp.i].t > 0 then
								if vehicle.aseChain.nodes[i-1].detected then
									c1 = 0
								else
									c1 = 0.5
								end
								c2 = 1
							else
								c1 = 1
								c2 = 1
							end
							
							drawDebugLine(lx1,py,lz1,c1,c2,c3,lx3,y,lz3,c1,c2,c3)

							if vehicle.aseChain.nodes[i-1].tool[tp.i].t < 0 then
								drawDebugLine(lx1,py,lz1,0.3,0.3,0.3,lx2,py,lz2,0.3,0.3,0.3)
							else
								drawDebugLine(lx1,py,lz1,0,0,1,lx2,py,lz2,0,0,1)
							end
						end
						
						px = wx 
						py = wy 
						pz = wz
					end		
				end
			end

			y = y + 1
			if vehicle.aseFruitAreas ~= nil and vehicle.aseFruitAreas[j] ~= nil and table.getn( vehicle.aseFruitAreas[j] ) == 9 then
				local lx1,lz1,lx2,lz2,lx3,lz3,lx4,lz4,g = unpack( vehicle.aseFruitAreas[j] )
				local c = {1,0,0}
				if g then
					if tp.skip then
						c = {1,1,0}
					else
						c = {0,1,0}
					end
				end
				
				drawDebugLine(lx1,y,lz1,c[1],c[2],c[3],lx3,y,lz3,c[1],c[2],c[3])
				drawDebugLine(lx1,y,lz1,c[1],c[2],c[3],lx2,y,lz2,c[1],c[2],c[3])
				drawDebugLine(lx4,y,lz4,c[1],c[2],c[3],lx2,y,lz2,c[1],c[2],c[3])
				drawDebugLine(lx4,y,lz4,c[1],c[2],c[3],lx3,y,lz3,c[1],c[2],c[3])
			elseif vehicle.aseFruitAreas ~= nil and vehicle.aseFruitAreas[j] ~= nil then
				print(tostring(table.getn( vehicle.aseFruitAreas[j] ) ) )
			end
		end
	end
	
	if ASEGlobals.showChannels > 0 then
		if vehicle.aseTestMap == nil and vehicle.aseCurrentField ~= nil then
			vehicle.aseTestMap = vehicle.aseCurrentField.getPoints()
			if vehicle.aseTestMap ~= nil then
				print(string.format("points: %i",table.getn(vehicle.aseTestMap)))
			end
		end
		
		if vehicle.aseTestMap ~= nil then
			for _,p in pairs( vehicle.aseTestMap ) do
				x,z = unpack( p )
				local y = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x, 1, z) + 2.2
				drawDebugPoint( x, y, z, 1,1,1, 1 )
			end
		end
	end
	
	if      vehicle.aseDirectionBeforeTurn             ~= nil 
			and vehicle.aseDirectionBeforeTurn.targetTrace ~= nil then
		local cr = 1
		if vehicle.aseDirectionBeforeTurn.targetTraceMode > 0 then
			cr = 0
		end
		for i,p in pairs( vehicle.aseDirectionBeforeTurn.targetTrace ) do
			
		
			drawDebugLine(  p.x, y, p.z,cr,1,0, p.x, y+4, p.z,cr,1,0)
			drawDebugPoint( p.x, y+4, p.z	, 1, 1, 1, 1 )
			drawDebugLine(  p.x, y+2, p.z,cr,1,0, p.x+p.dx, y+2, p.z+p.dz,cr,0,1)
		end
	end
	
end

------------------------------------------------------------------------
-- displayDebugInfo
------------------------------------------------------------------------
function AutoSteeringEngine.displayDebugInfo( vehicle )

	if vehicle.isControlled then
		setTextBold(false)
		setTextColor(1, 1, 1, 1)
		setTextAlignment(RenderText.ALIGN_LEFT)
		
		local fullText = ""
		
		fullText = fullText .. string.format("AutoTractor:") .. "\n"
		
		renderText(0.51, 0.97, 0.02, fullText)		
	end
	
end

------------------------------------------------------------------------
-- getFruitArea
------------------------------------------------------------------------
function AutoSteeringEngine.getFruitArea( vehicle, x1,z1,x2,z2,d,toolIndex,noMinLength )
	local lx1,lz1,lx2,lz2,lx3,lz3 = AutoSteeringEngine.getParallelogram( x1, z1, x2, z2, d, noMinLength )
	return AutoSteeringEngine.getFruitAreaWorldPositions( vehicle, vehicle.aseTools[toolIndex], lx1,lz1,lx2,lz2,lx3,lz3,noMinLength )
end

------------------------------------------------------------------------
-- getTerrainDetailRequiredMask
------------------------------------------------------------------------
function AutoSteeringEngine.getTerrainDetailRequiredMask( groundInfoObject )
	local terrainDetailRequiredMask = 0
	if groundInfoObject.aiTerrainDetailChannel1 >= 0 then
		terrainDetailRequiredMask = bitOR(terrainDetailRequiredMask, 2^groundInfoObject.aiTerrainDetailChannel1)
		if groundInfoObject.aiTerrainDetailChannel2 >= 0 then
			terrainDetailRequiredMask = bitOR(terrainDetailRequiredMask, 2^groundInfoObject.aiTerrainDetailChannel2)
			if groundInfoObject.aiTerrainDetailChannel3 >= 0 then
				terrainDetailRequiredMask = bitOR(terrainDetailRequiredMask, 2^groundInfoObject.aiTerrainDetailChannel3)
				if groundInfoObject.aiTerrainDetailChannel4 >= 0 then
					terrainDetailRequiredMask = bitOR(terrainDetailRequiredMask, 2^groundInfoObject.aiTerrainDetailChannel4)
				end
			end
		end
	end
	return terrainDetailRequiredMask
end

------------------------------------------------------------------------
-- removeTerrainDetailChannel
------------------------------------------------------------------------
function AutoSteeringEngine.removeTerrainDetailChannel( groundInfoObject, channel )
	local removed = false
	if groundInfoObject.aiTerrainDetailChannel1 == channel then
		groundInfoObject.aiTerrainDetailChannel1 = groundInfoObject.aiTerrainDetailChannel2
		groundInfoObject.aiTerrainDetailChannel2 = groundInfoObject.aiTerrainDetailChannel3
		groundInfoObject.aiTerrainDetailChannel3 = groundInfoObject.aiTerrainDetailChannel4
		groundInfoObject.aiTerrainDetailChannel4 = -1
		removed = true
	end
	if groundInfoObject.aiTerrainDetailChannel2 == channel then
		groundInfoObject.aiTerrainDetailChannel2 = groundInfoObject.aiTerrainDetailChannel3
		groundInfoObject.aiTerrainDetailChannel3 = groundInfoObject.aiTerrainDetailChannel4
		groundInfoObject.aiTerrainDetailChannel4 = -1
		removed = true
	end
	if groundInfoObject.aiTerrainDetailChannel3 == channel then
		groundInfoObject.aiTerrainDetailChannel3 = groundInfoObject.aiTerrainDetailChannel4
		groundInfoObject.aiTerrainDetailChannel4 = -1
		removed = true
	end
	if groundInfoObject.aiTerrainDetailChannel4 == channel then
		groundInfoObject.aiTerrainDetailChannel4 = -1
		removed = true
	end
	if removed then
		groundInfoObject.aiTerrainDetailProhibitedMask = bitOR(groundInfoObject.aiTerrainDetailProhibitedMask, 2^g_currentMission.sowingChannel)
		groundInfoObject.aiTerrainDetailProhibitedMask = bitOR(groundInfoObject.aiTerrainDetailProhibitedMask, 2^g_currentMission.sowingWidthChannel)	
	end
end
	
------------------------------------------------------------------------
-- getFruitAreaWorldPositions
------------------------------------------------------------------------
function AutoSteeringEngine.getFruitAreaWorldPositions( vehicle, tool, lx1,lz1,lx2,lz2,lx3,lz3,origAI )

	local area, areaTotal = 0,0
	if tool.isCombine then
		area, areaTotal = Utils.getFruitArea(tool.obj.lastValidInputFruitType, lx1,lz1,lx2,lz2,lx3,lz3,false)	
	elseif tool.isMower then
		area, areaTotal = Utils.getFruitArea(FruitUtil.FRUITTYPE_GRASS, lx1,lz1,lx2,lz2,lx3,lz3,false)	
	elseif tool.isWindrower then
		area, areaTotal = AutoSteeringEngine.getWindrowArea(lx1,lz1,lx2,lz2,lx3,lz3)
	elseif tool.isTedder then
		area, areaTotal = AutoSteeringEngine.getFruitWindrowArea(FruitUtil.FRUITTYPE_GRASS,lx1,lz1,lx2,lz2,lx3,lz3)
	else
		local groundInfoObject = tool
		local terrainDetailRequiredMask = tool.aiTerrainDetailRequiredMask
	--if origAI and tool.isAITool and tool.obj ~= nil then
	--	terrainDetailRequiredMask = AutoSteeringEngine.getTerrainDetailRequiredMask( tool.obj )
	--end
		
		area, areaTotal = AutoSteeringEngine.getAIArea( vehicle, 
																										lx1, lz1, lx2, lz2, lx3, lz3, 
																										terrainDetailRequiredMask, 
																										groundInfoObject.aiTerrainDetailProhibitedMask, 
																										groundInfoObject.aiRequiredFruitType, 
																										groundInfoObject.aiRequiredMinGrowthState, 
																										groundInfoObject.aiRequiredMaxGrowthState, 
																										groundInfoObject.aiProhibitedFruitType, 
																										groundInfoObject.aiProhibitedMinGrowthState, 
																										groundInfoObject.aiProhibitedMaxGrowthState )
	end
	
	return area, areaTotal
end

------------------------------------------------------------------------
-- getFruitWindrowArea
------------------------------------------------------------------------
function AutoSteeringEngine.getFruitWindrowArea(fruitId, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
  local ids = g_currentMission.fruits[fruitId]
  if ids == nil or ids.windrowId == 0 then
    return 0,0
  end
  local windrowId = ids.windrowId
  local maskId = windrowId
  local numMaskChannels = g_currentMission.numWindrowChannels
  local x, z, widthX, widthZ, heightX, heightZ = Utils.getXZWidthAndHeight(windrowId, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
  local area,_,totalArea = getDensityMaskedParallelogram(windrowId, x, z, widthX, widthZ, heightX, heightZ, 0, g_currentMission.numWindrowChannels, maskId, 0, numMaskChannels, value)
  return area,totalArea
end

------------------------------------------------------------------------
-- getWindrowArea
------------------------------------------------------------------------
function AutoSteeringEngine.getWindrowArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
  local fruitType = FruitUtil.FRUITTYPE_DRYGRASS
  local area,totalArea = AutoSteeringEngine.getFruitWindrowArea(fruitType, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
  if area == 0 then
    for fruitId = 1, FruitUtil.NUM_FRUITTYPES do
      if fruitId ~= FruitUtil.FRUITTYPE_DRYGRASS then
        local ids = g_currentMission.fruits[fruitId]
        if ids ~= nil and ids.windrowId ~= 0 then
          fruitType = fruitId
          area,totalArea = AutoSteeringEngine.getFruitWindrowArea(fruitType, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
          if area > 0 then
						local a, t = Utils.getFruitWindrowArea(fruitType, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
						area = math.max( area - a, 0 )
            break
          end
        end
      end
    end
  end
  return area,totalArea
end

------------------------------------------------------------------------
-- getAIArea
------------------------------------------------------------------------

function AutoSteeringEngine.getAIArea( vehicle, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, terrainDetailRequiredMask, terrainDetailProhibitedMask, requiredFruitType, requiredMinGrowthState, requiredMaxGrowthState, prohibitedFruitType, prohibitedMinGrowthState, prohibitedMaxGrowthState)
	if false then
		return AITractor.getAIArea( vehicle, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, terrainDetailRequiredMask, terrainDetailProhibitedMask, requiredFruitType, requiredMinGrowthState, requiredMaxGrowthState, prohibitedFruitType, prohibitedMinGrowthState, prohibitedMaxGrowthState)
	end
	
	local area = 0
	local totalArea = 0
	local prohibitedArea = 0
	
	if terrainDetailRequiredMask > 0 then
		local detailId = g_currentMission.terrainDetailId
		local x,z, widthX,widthZ, heightX,heightZ = Utils.getXZWidthAndHeight(detailId, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
		setDensityCompareParams(detailId, "greater", 0, 0, terrainDetailRequiredMask, terrainDetailProhibitedMask)
		_,area,totalArea = getDensityParallelogram(detailId, x, z, widthX, widthZ, heightX, heightZ, g_currentMission.terrainDetailAIFirstChannel, g_currentMission.terrainDetailAINumChannels)
		if prohibitedFruitType ~= FruitUtil.FRUITTYPE_UNKNOWN and area > 0 then
			local ids = g_currentMission.fruits[prohibitedFruitType]
			if ids ~= nil and ids.id ~= 0 then
				setDensityMaskParams(detailId, "between", prohibitedMinGrowthState+1, prohibitedMaxGrowthState+1) -- only fruit outside the given range is allowed
				local _,prohibitedArea = getDensityMaskedParallelogram(detailId, x, z, widthX, widthZ, heightX, heightZ, g_currentMission.terrainDetailAIFirstChannel, g_currentMission.terrainDetailAINumChannels, ids.id, 0, g_currentMission.numFruitStateChannels)
				setDensityMaskParams(detailId, "greater", 0)
				area = area - prohibitedArea				
			end
		end
		setDensityCompareParams(detailId, "greater", -1)
	elseif requiredFruitType ~= FruitUtil.FRUITTYPE_UNKNOWN then
		local ids = g_currentMission.fruits[requiredFruitType]
		if ids ~= nil and ids.id ~= 0 then
			local x,z, widthX,widthZ, heightX,heightZ = Utils.getXZWidthAndHeight(ids.id, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
			setDensityCompareParams(ids.id, "between", requiredMinGrowthState+1, requiredMaxGrowthState+1)
			if terrainDetailProhibitedMask ~= 0 then
				local detailId = g_currentMission.terrainDetailId
				setDensityMaskParams(ids.id, "greater", 0, 0, 0, terrainDetailProhibitedMask)
				_,area,totalArea = getDensityMaskedParallelogram(ids.id, x, z, widthX, widthZ, heightX, heightZ, 0, g_currentMission.numFruitStateChannels, detailId, g_currentMission.terrainDetailAIFirstChannel, g_currentMission.terrainDetailAINumChannels)
				setDensityMaskParams(ids.id, "greater", 0)
			else
				_,area,totalArea = getDensityParallelogram(ids.id, x, z, widthX, widthZ, heightX, heightZ, 0, g_currentMission.numFruitStateChannels)
			end
			setDensityCompareParams(ids.id, "greater", -1)
		end
	end
	return area,totalArea
end

------------------------------------------------------------------------
-- applySteering
------------------------------------------------------------------------
function AutoSteeringEngine.applySteering( vehicle, toIndex )

	if vehicle.aseMinAngle == nil or vehicle.aseMaxAngle == nil then
		vehicle.aseMinAngle = -vehicle.aseChain.maxSteering
		vehicle.aseMaxAngle = vehicle.aseChain.maxSteering
	end

	local a  = vehicle.aseSteeringAngle
	local j0 = ASEGlobals.chainMax+2
	local af = math.abs(vehicle.aseMaxAngle) + math.abs(vehicle.aseMinAngle)
	
	if af > math.abs( vehicle.aseAngleFactor ) then
		af = vehicle.aseAngleFactor
	elseif vehicle.aseAngleFactor < 0 then
		af = -af
	end
	
	local jMax = ASEGlobals.chainMax
	if toIndex ~= nil and toIndex < ASEGlobals.chainMax then 
		jMax = toIndex 
	end
	for j=1,jMax do 
	--for j=1,ASEGlobals.chainMax+1 do 
		local b = a

		if j == 1 and AutoSteeringEngine.isSetAngleZero( vehicle ) then 
			local aMin, aMax 
			
			if vehicle.aseLRSwitch	then
				aMin, aMax = -vehicle.aseMinAngle, vehicle.aseMaxAngle
			else
				aMin, aMax = vehicle.aseMaxAngle, -vehicle.aseMinAngle
			end
			
			if math.abs( vehicle.aseChain.nodes[j].angle ) < 1E-4 then
				b = 0 
			elseif vehicle.aseChain.nodes[j].angle > 0 then 
				-- outside 
				b = aMax * vehicle.aseChain.nodes[j].angle 
			else 	
				-- inside
				b = aMin * vehicle.aseChain.nodes[j].angle
			end
			
			if not vehicle.aseLRSwitch	then
				b = -b 
			end
		else
			local c = af * vehicle.aseChain.nodes[j].angle
			
			if ASEGlobals.angleStepDec > 0 then
				c = c * math.max( 0.1, 1 - vehicle.aseChain.nodes[j].distance * ASEGlobals.angleStepDec / ASEGlobals.angleStep )
			end
		
			if     ( vehicle.aseAngleFactor > 0 and b > 0 )
					or ( vehicle.aseAngleFactor < 0 and b < 0 ) then
				b = ( a + c ) * ASEGlobals.angleOutsideFactor
			else
				b = ( a + c ) * ASEGlobals.angleInsideFactor
			end
		end
		
		a  = Utils.clamp( b, vehicle.aseMinAngle, vehicle.aseMaxAngle )
		
		if j0 > j and vehicle.aseChain.nodes[j].status < ASEStatus.steering then
			j0 = j
		end
		if j >= j0 then
			vehicle.aseChain.nodes[j].steering  = a
			vehicle.aseChain.nodes[j].tool      = {}
			vehicle.aseChain.nodes[j].radius    = 1E+6
			if math.abs(a) > 1E-5 then
				vehicle.aseChain.nodes[j].radius  = vehicle.aseChain.wheelBase / math.tan( a )
			end
			vehicle.aseChain.nodes[j].invRadius = vehicle.aseChain.invWheelBase * math.tan( a )			
			vehicle.aseChain.nodes[j].status    = ASEStatus.steering
		end
	end 
end

------------------------------------------------------------------------
-- applyRotation
------------------------------------------------------------------------
function AutoSteeringEngine.applyRotation( vehicle, toIndex )

	local cumulRot, turnAngle = 0, 0
	if vehicle.acTurnStage ~= nil and vehicle.acTurnStage == 0 then
		cumulRot  = AutoSteeringEngine.getTurnAngle( vehicle )
		turnAngle = AutoSteeringEngine.getTurnAngle( vehicle )
	end 

	if not vehicle.isServer then return end
	
	AutoSteeringEngine.applySteering( vehicle, toIndex )

	local j0 = ASEGlobals.chainMax+2
	local jMax = ASEGlobals.chainMax
	if toIndex ~= nil and toIndex < ASEGlobals.chainMax then 
		jMax = toIndex 
	end
	for j=1,jMax do 
		if j0 > j and vehicle.aseChain.nodes[j].status < ASEStatus.rotation then
			j0 = j
		end
		if j >= j0 then
			vehicle.aseChain.nodes[j].tool = {}		
		
			--vehicle.aseChain.nodes[j].rotation = math.tan( vehicle.aseChain.nodes[j].steering ) * vehicle.aseChain.invWheelBase
			local length = vehicle.aseChain.nodes[j+1].distance - vehicle.aseChain.nodes[j].distance		
			local updateSteering

			if toIndex ~= nil and j > toIndex then
				vehicle.aseChain.nodes[j].rotation = 0
				updateSteering = true
			else
				vehicle.aseChain.nodes[j].rotation = 2 * math.asin( length * 0.5 * vehicle.aseChain.nodes[j].invRadius )
				updateSteering = false
			end
			
			--if vehicle.aseChain.isInverted then
			--	vehicle.aseChain.nodes[j].rotation = -vehicle.aseChain.nodes[j].rotation
			--end
			
			local oldCumulRot = cumulRot
			cumulRot = cumulRot + vehicle.aseChain.nodes[j].rotation
			
			if vehicle.aseSmooth ~= nil then
				local restRot = ( 1 - vehicle.aseSmooth * ASEGlobals.angleInsideFactor2 ) * vehicle.aseChain.nodes[j].rotation
				
				if     ( vehicle.aseChain.nodes[j].rotation > 0 
						 and turnAngle + cumulRot > 0
						 and not ( vehicle.aseLRSwitch ) )
						or ( vehicle.aseChain.nodes[j].rotation < 0 
						 and turnAngle + cumulRot < 0
						 and vehicle.aseLRSwitch ) then
					updateSteering = true
					if math.abs( turnAngle + cumulRot ) > math.abs( restRot ) then	
						vehicle.aseChain.nodes[j].rotation = vehicle.aseChain.nodes[j].rotation - restRot
					else
						vehicle.aseChain.nodes[j].rotation = vehicle.aseChain.nodes[j].rotation - turnAngle + cumulRot						
					end
				end
			end

			if     cumulRot >  vehicle.aseMaxRotation then
				vehicle.aseChain.nodes[j].rotation = vehicle.aseChain.nodes[j].rotation + vehicle.aseMaxRotation - cumulRot
				updateSteering                     = true
			elseif cumulRot < -vehicle.aseMaxRotation then
				vehicle.aseChain.nodes[j].rotation = vehicle.aseChain.nodes[j].rotation - vehicle.aseMaxRotation - cumulRot
				updateSteering                     = true
			end
			
			if updateSteering then
				cumulRot = oldCumulRot + vehicle.aseChain.nodes[j].rotation
				vehicle.aseChain.nodes[j].steering = math.atan( 0.5 * math.sin( vehicle.aseChain.nodes[j].rotation ) * vehicle.aseChain.wheelBase / length )
				vehicle.aseChain.nodes[j].tool      = {}
				vehicle.aseChain.nodes[j].radius    = 0
				if math.abs( vehicle.aseChain.nodes[j].steering ) > 1E-5 then
					vehicle.aseChain.nodes[j].radius  = vehicle.aseChain.wheelBase / math.tan( vehicle.aseChain.nodes[j].steering )			
				end		
				vehicle.aseChain.nodes[j].invRadius = vehicle.aseChain.invWheelBase * math.tan( vehicle.aseChain.nodes[j].steering )			
			end

			vehicle.aseChain.nodes[j].cumulRot = cumulRot
			
			setRotation( vehicle.aseChain.nodes[j].index2, 0, vehicle.aseChain.nodes[j].rotation, 0 )
			vehicle.aseChain.nodes[j].status   = ASEStatus.rotation
		else
			cumulRot = cumulRot + vehicle.aseChain.nodes[j].rotation
		end
	end 
end

------------------------------------------------------------------------
-- invalidateField
------------------------------------------------------------------------
function AutoSteeringEngine.invalidateField( vehicle, force )
	--if not ( vehicle.aseFieldIsInvalid ) then print("invalidating field") end
	vehicle.aseFieldIsInvalid = true
	vehicle.aseLastBestAngle  = nil
	if force then
		vehicle.aseCurrentField = nil		
	end
end

------------------------------------------------------------------------
-- checkFieldNoBuffer
------------------------------------------------------------------------
 function AutoSteeringEngine.checkFieldNoBuffer( x, z, checkFunction ) 

	if x == nil or z == nil or checkFunction == nil then
		--AutoTractor.printCallstack()
		return false
	end 
	
	if checkFunction == FieldBitmap.isFieldFast then
		return (getDensityAtWorldPos(g_currentMission.terrainDetailId, x, z) % 16) > 0 
--	if g_currentMission.aseGlobalFieldBitmap == nil then
--		g_currentMission.aseGlobalFieldBitmap  = FieldBitmap.create( ASEGlobals.stepLog2 )
--		g_currentMission.aseGlobalFieldChecked = FieldBitmap.create( ASEGlobals.stepLog2 )
--	end
--	
--	if not g_currentMission.aseGlobalFieldChecked.tileExists( x, z ) then
--		local x1, z1, l1 = g_currentMission.aseGlobalFieldBitmap.getTileDimensions( x, z )
--		local a, t = FieldBitmap.getAreaTotal( FieldBitmap.getParallelogram( x1, z1, l1, 2^(-ASEGlobals.stepLog2-1) ) )
--		if     a == 0 then
--			g_currentMission.aseGlobalFieldChecked.createOneTile( x, z )
--		elseif a == t then
--			g_currentMission.aseGlobalFieldChecked.createOneTile( x, z )
--			g_currentMission.aseGlobalFieldBitmap.createOneTile( x, z )
--		end
--	end
--	
--	if g_currentMission.aseGlobalFieldChecked.getBit( x, z ) then
--		return g_currentMission.aseGlobalFieldBitmap.getBit( x, z )
--	end
	end 
	
	FieldBitmap.prepareIsField( )
	local startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ = FieldBitmap.getParallelogram( x, z, 0.5, 0.25 )
	local ret = checkFunction( startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ )
	FieldBitmap.cleanupAfterIsField( )
	
--if checkFunction == FieldBitmap.isFieldFast then
--	g_currentMission.aseGlobalFieldChecked.setBit( x, z )
--	if ret then
--		g_currentMission.aseGlobalFieldBitmap.setBit( x, z )		
--	end
--end
	
	return ret
end

------------------------------------------------------------------------
-- hasMower
------------------------------------------------------------------------
function AutoSteeringEngine.hasMower( vehicle )
	if ( vehicle.aseChain ~= nil and vehicle.aseLRSwitch ~= nil and vehicle.aseToolCount ~= nil and vehicle.aseToolCount >= 1 ) then
		if     vehicle.aseHas.mower then 
			return true 
		elseif vehicle.aseHas.combine then  
			for i=1,vehicle.aseToolCount do
				if vehicle.aseTools[i].isCombine and vehicle.aseTools[i].obj.lastValidInputFruitType == FruitUtil.FRUITTYPE_GRASS then
					return true
				end 
			end
		end
	end
	
	return false
end

------------------------------------------------------------------------
-- hasWindrower
------------------------------------------------------------------------
function AutoSteeringEngine.hasWindrower( vehicle )
	if ( vehicle.aseChain ~= nil and vehicle.aseLRSwitch ~= nil and vehicle.aseToolCount ~= nil and vehicle.aseToolCount >= 1 ) and vehicle.aseHas.windrower then
		return true 
	end
	return false
end

------------------------------------------------------------------------
-- hasTedder
------------------------------------------------------------------------
function AutoSteeringEngine.hasTedder( vehicle )
	if ( vehicle.aseChain ~= nil and vehicle.aseLRSwitch ~= nil and vehicle.aseToolCount ~= nil and vehicle.aseToolCount >= 1 ) and vehicle.aseHas.tedder then
		return true
	end	
	return false
end

------------------------------------------------------------------------
-- areaTotalSpecial
------------------------------------------------------------------------
function AutoSteeringEngine.areaTotalSpecial( x, z, ownedBy, mode, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ )
	
	local dx = x - startWorldX
	local dz = z - startWorldZ
	if ownedBy then
		local lx4 = heightWorldX + widthWorldX - startWorldX
		local lz4 = heightWorldZ + widthWorldZ - startWorldZ
		if      not g_currentMission:getIsFieldOwnedAtWorldPos( startWorldX,  startWorldZ )
				and not g_currentMission:getIsFieldOwnedAtWorldPos( widthWorldX,  widthWorldZ )
				and not g_currentMission:getIsFieldOwnedAtWorldPos( heightWorldX, heightWorldZ )
				and not g_currentMission:getIsFieldOwnedAtWorldPos( lx4, lz4 ) then
			return 0,0
		end
	end
	if Utils.vector2LengthSq( dx, dz ) > 1000000 then 
		return 0,0 
	end
	
  local a, t = 0, 0
	if     mode == 1 then
		a, t = Utils.getFruitArea( FruitUtil.FRUITTYPE_GRASS, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, false )	
	elseif mode == 2 then
		a, t = AutoSteeringEngine.getWindrowArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)	
	elseif mode == 3 then
		a, t = AutoSteeringEngine.getFruitWindrowArea(FruitUtil.FRUITTYPE_GRASS, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)	
	end
	
	if      widthWorldX - startWorldX < 2 
			and widthWorldZ - startWorldZ < 2 
			and a+a+a+a < t+t+t then
		a = 0
	end
	return a,t
end

function AutoSteeringEngine.checkSpecialField( x, z, ownedBy, mode, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ )
	return ( 0 < AutoSteeringEngine.areaTotalSpecial( x, z, ownedBy, mode, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ ) )
end

------------------------------------------------------------------------
-- getCheckFunction
------------------------------------------------------------------------
function AutoSteeringEngine.getCheckFunction( vehicle )

	local checkFct, areaTotalFct
	
	if     AutoSteeringEngine.hasMower( vehicle ) 
			or AutoSteeringEngine.hasWindrower( vehicle )
			or AutoSteeringEngine.hasTedder( vehicle ) then 	
		local x1,_,z1= localToWorld( vehicle.aseChain.refNode, 0.5 * ( vehicle.aseActiveX + vehicle.aseOtherX ), 0, 0 )
		local buffer = {}
		buffer.x     = x1
		buffer.z     = z1
		buffer.o     = g_currentMission:getIsFieldOwnedAtWorldPos( buffer.x, buffer.z )
		buffer.m     = 0
		
		if     AutoSteeringEngine.hasMower( vehicle ) then
			buffer.m = 1
		elseif AutoSteeringEngine.hasWindrower( vehicle ) then		
			buffer.m = 2
		elseif AutoSteeringEngine.hasTedder( vehicle ) then 
			buffer.m = 3
		end

		checkFct     = function( startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ )
			return AutoSteeringEngine.checkSpecialField( buffer.x, buffer.z, buffer.o, buffer.m, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ )
		end
		areaTotalFct = function( startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ )
			return AutoSteeringEngine.areaTotalSpecial( buffer.x, buffer.z, buffer.o, buffer.m, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ )
		end

	else
		checkFct     = FieldBitmap.isFieldFast
		areaTotalFct = FieldBitmap.getAreaTotal
	end

	return checkFct, areaTotalFct
end

------------------------------------------------------------------------
-- checkField
------------------------------------------------------------------------
function AutoSteeringEngine.checkField( vehicle, x, z )

	local stepLog2 = ASEGlobals.stepLog2

	if vehicle.aseFieldIsInvalid then
		vehicle.aseChain.lastX = nil
		vehicle.aseChain.lastZ = nil 
		vehicle.aseCurrentFieldCo = nil
		vehicle.aseCurrentFieldCS = 'dead'
		vehicle.aseCurrentWorkArea = nil
	
		if vehicle.aseCurrentField ~= nil then
			local x1,_,z1 = localToWorld( vehicle.aseChain.refNode, 0.5 * ( vehicle.aseActiveX + vehicle.aseOtherX ), 0, 0 )
			if vehicle.aseCurrentField.getBit( x1, z1 ) then
				vehicle.aseFieldIsInvalid = false			
			else
				local checkFunction, areaTotalFunction = AutoSteeringEngine.getCheckFunction( vehicle )
				if AutoSteeringEngine.checkFieldNoBuffer( x1, z1, checkFunction ) then
					vehicle.aseCurrentField = nil	
				end
			end
		end
	end
	
	if vehicle.aseCurrentField == nil then
		vehicle.aseFieldIsInvalid = false
		
		local status, hektar = false, 0
		
		if vehicle.aseCurrentFieldCo == nil then
			local checkFunction, areaTotalFunction = AutoSteeringEngine.getCheckFunction( vehicle )
			local x1,_,z1 = AutoSteeringEngine.getAiWorldPosition( vehicle )
			if vehicle.aseChain.lastX ~= nil and vehicle.aseChain.lastZ ~= nil then
				if Utils.vector2LengthSq( vehicle.aseChain.lastX - x1, vehicle.aseChain.lastZ - z1 ) < 1 then
					return true
				else
					vehicle.aseChain.lastX = x1
					vehicle.aseChain.lastZ = z1 
				end
			end
		
			x1,_,z1 = localToWorld( vehicle.aseChain.refNode, 0.5 * ( vehicle.aseActiveX + vehicle.aseOtherX ), 0, 0 )
			local found = AutoSteeringEngine.checkFieldNoBuffer( x1, z1, checkFunction )
			
			if not found then
				local i = 1
				repeat
					if vehicle.aseTools == nil or vehicle.aseTools[i] == nil then
						break
					end
				
					x1,_,z1 = getWorldTranslation( vehicle.aseTools[i].steeringAxleNode )
					found   = AutoSteeringEngine.checkFieldNoBuffer( x1, z1, checkFunction )
					if not found then
						for m=1,table.getn( vehicle.aseTools[i].marker ) do
							x1,_,z1 = getWorldTranslation( vehicle.aseTools[i].marker[m] )
							found   = AutoSteeringEngine.checkFieldNoBuffer( x1, z1, checkFunction )
							if found then break end
						end
					end
					i = i + 1
				until found
			end
			
			if found then
				if ASEGlobals.yieldCount < 1 then
					if checkFunction == AutoSteeringEngine.checkMowerField then
						vehicle.aseCurrentField, hektar = FieldBitmap.createForFieldAtWorldPosition( x1, z1, stepLog2, 1, areaTotalFunction, nil, nil, 0 )
					else
						vehicle.aseCurrentField, hektar = FieldBitmap.createForFieldAtWorldPositionSimple( x1, z1, stepLog2, 1, checkFunction )
					end
					vehicle.aseCurrentFieldCo = nil
					vehicle.aseCurrentFieldCS = 'dead'
				else
					if checkFunction == AutoSteeringEngine.checkMowerField then
						vehicle.aseCurrentFieldCo = coroutine.create( FieldBitmap.createForFieldAtWorldPosition )
						status, vehicle.aseCurrentField, hektar = coroutine.resume( vehicle.aseCurrentFieldCo, x1, z1, stepLog2, 1, areaTotalFunction, nil, nil, ASEGlobals.yieldCount )
					else
						vehicle.aseCurrentFieldCo = coroutine.create( FieldBitmap.createForFieldAtWorldPositionSimple )
						status, vehicle.aseCurrentField, hektar = coroutine.resume( vehicle.aseCurrentFieldCo, x1, z1, stepLog2, 1, checkFunction, ASEGlobals.yieldCount )
					end
					if status then
						vehicle.aseCurrentFieldCS = coroutine.status( vehicle.aseCurrentFieldCo )
					else
						print("Field detection failed: "..tostring(vehicle.aseCurrentField))
						vehicle.aseCurrentField   = nil
						vehicle.aseCurrentFieldCo = nil
						vehicle.aseCurrentFieldCS = 'dead'
					end
				end
			end
		elseif vehicle.aseCurrentFieldCS ~= 'dead' then
			status, vehicle.aseCurrentField, hektar = coroutine.resume( vehicle.aseCurrentFieldCo )				
			if status then
				vehicle.aseCurrentFieldCS = coroutine.status( vehicle.aseCurrentFieldCo )
			else
				print("Field detection failed: "..tostring(vehicle.aseCurrentField))
				vehicle.aseCurrentField   = nil
				vehicle.aseCurrentFieldCo = nil
				vehicle.aseCurrentFieldCS = 'dead'
			end
		end
		
		if vehicle.aseCurrentFieldCo ~= nil then
			if vehicle.aseCurrentFieldCS == 'dead' then
				vehicle.aseCurrentFieldCo = nil
			else
				g_currentMission:addWarning(string.format("Field detection is running (%0.3f ha)", hektar), 0.018, 0.033)
				if vehicle.aseCurrentField ~= nil then
					print("ups")
					vehicle.aseCurrentField = nil
				end
			end
		end
	end
	
	if vehicle.aseCurrentField == nil then 
		return true
	else
		return vehicle.aseCurrentField.getBit( x, z )
	end
end

------------------------------------------------------------------------
-- isFieldAhead
------------------------------------------------------------------------
function AutoSteeringEngine.isFieldAhead( vehicle, distance, node )
	if node == nil then
		node = vehicle.aseChain.refNode
	end
	
	local w = math.max( 1, 0.25 * vehicle.aseWidth )--+ 0.13 * vehicle.aseHeadland )
	
	for j=-2,2 do
		local x,y,z = localToWorld( node, j * w, 0, distance )
		if AutoSteeringEngine.checkField( vehicle, x, z ) then return true end
	end
	return false
	
end

------------------------------------------------------------------------
-- initHeadlandVector
------------------------------------------------------------------------
function AutoSteeringEngine.initHeadlandVector( vehicle )

--if vehicle.aseIsTurnMode7 then
--	vehicle.aseHeadland = vehicle.aseWidth 
--end

	if      vehicle.aseChain         ~= nil
	    and vehicle.aseChain.refNode ~= nil then
		local x,_,z = AutoSteeringEngine.getAiWorldPosition( vehicle )
		if     vehicle.aseCollisions == nil
				or vehicle.aseCollisionX == nil
				or vehicle.aseCollisionZ == nil
				or Utils.vector2LengthSq( vehicle.aseCollisionX - x, vehicle.aseCollisionZ - z ) > 2 then
			vehicle.aseCollisions      = {}
			vehicle.aseCollisionX      = x
			vehicle.aseCollisionZ      = z
			vehicle.aseCollisionPoints = nil
		end
	end
	
	if not vehicle.isServer then return end
	
	AutoSteeringEngine.rotateHeadlandNode( vehicle )
	local w = vehicle.aseWidth
	local w = math.max( 1, 0.25 * w )--+ 0.13 * vehicle.aseHeadland )	
	local d = 0
	if      ASEGlobals.ignoreDist > 0 
			and vehicle.aseTurnMode  ~= "C"
			and vehicle.aseTurnMode  ~= "L"
			and vehicle.aseTurnMode  ~= "K" 
			and vehicle.aseTurnMode  ~= "7" then
		if d < ASEGlobals.ignoreDist then
			d = ASEGlobals.ignoreDist
		end
		if ( vehicle.aseChain ~= nil and vehicle.aseLRSwitch ~= nil and vehicle.aseToolCount ~= nil and vehicle.aseToolCount >= 1 ) then
			for i=1,table.getn(vehicle.aseToolParams) do
				local d2 = math.abs( vehicle.aseToolParams[i].zReal - vehicle.aseToolParams[i].zBack )
				if d < d2 and vehicle.aseTools[vehicle.aseToolParams[i].i].isSowingMachine then 
					d = d2
				end
			end
		end
	end
	d = d + vehicle.aseHeadland
	
	vehicle.aseHeadlandVector       = {}
	vehicle.aseHeadlandVector.front = {}
	vehicle.aseHeadlandVector.back  = {}
	for j=1,5 do
		local front = {}
		front.x,_,front.z   = localDirectionToWorld( vehicle.aseChain.headlandNode, (j-3)*w, 0, d )
		--front.x1,_,front.z1 = localDirectionToWorld( vehicle.aseChain.headlandNode, (j-3)*w, 0, 1 )
		vehicle.aseHeadlandVector.front[j] = front
		
		local back  = {}
		back.x,_,back.z   = localDirectionToWorld( vehicle.aseChain.headlandNode, (j-3)*w, 0,-d )
		--back.x1,_,back.z1 = localDirectionToWorld( vehicle.aseChain.headlandNode, (j-3)*w, 0, 1 )
		vehicle.aseHeadlandVector.back[j]  = back
	end
end

------------------------------------------------------------------------
-- isChainPointOnField
------------------------------------------------------------------------
function AutoSteeringEngine.isChainPointOnField( vehicle, xw, zw )
	if not vehicle.isServer then return true end
	
	local front = false
	local back  = false

	for j=1,5 do
		if AutoSteeringEngine.checkField( vehicle, xw + vehicle.aseHeadlandVector.front[j].x, zw + vehicle.aseHeadlandVector.front[j].z ) then
			front = true
		end
		if AutoSteeringEngine.checkField( vehicle, xw + vehicle.aseHeadlandVector.back[j].x, zw + vehicle.aseHeadlandVector.back[j].z ) then
			back = true
		end
	end
	
	return front and back
end

------------------------------------------------------------------------
-- isNotHeadland
------------------------------------------------------------------------
function AutoSteeringEngine.isNotHeadland( vehicle, distance )
	local x,y,z
	local fRes  = true
	local angle = AutoSteeringEngine.getTurnAngle( vehicle )
	local dist  = distance
	
	if vehicle.aseHeadland < 1E-3 then return true end
	
	if math.abs(angle)> 0.5*math.pi then
		dist = -dist
	end
	
	--if vehicle.aseHeadland > 0 then		
		setRotation( vehicle.aseChain.headlandNode, 0, -angle, 0 )
		
		local d = dist + ( vehicle.aseHeadland + 1 )
		for i=0,d do
			if not AutoSteeringEngine.isFieldAhead( vehicle, d, vehicle.aseChain.headlandNode ) then
				fRes = false
				break
			end
		end
		
		if fRes then
			d = dist - ( vehicle.aseHeadland + 1 )
			for i=0,d do
				if not AutoSteeringEngine.isFieldAhead( vehicle, d, vehicle.aseChain.headlandNode ) then
					fRes = false
					break
				end
			end
		end
	--end
	
	return fRes
end

------------------------------------------------------------------------
-- getChainPoint
------------------------------------------------------------------------
function AutoSteeringEngine.getChainPoint( vehicle, i, tp )

	if not vehicle.isServer then return 0,0 end
	
	local invert = false
	local dx,dz  = 0,0
	local aRef   = 0
	local tpx    = tp.x
	local dtpx   = 0
	
	if i > 1 and ASEGlobals.widthDec ~= 0 then
		local w = tp.width
		if 0 < ASEGlobals.widthMaxDec and ASEGlobals.widthMaxDec < w then
			w = ASEGlobals.widthMaxDec
		end
		dtpx = w * ASEGlobals.widthDec * vehicle.aseChain.nodes[i].distance
	end
--	if i > 1 and ASEGlobals.widthDec ~= 0 then
--		dtpx = tp.width * ASEGlobals.widthDec * vehicle.aseChain.length * (i-1)/ASEGlobals.chainMax
--	end
--	if i <= ASEGlobals.widthDec + 1 then
--		dtpx = -tp.offset * ( i - 1 ) / ASEGlobals.widthDec
--	end
	
	if vehicle.aseLRSwitch then
		tpx = tpx - dtpx
	else
		tpx = tpx + dtpx
	end
	
	if     vehicle.aseChain.nodes[i].status < ASEStatus.position
      or vehicle.aseChain.nodes[i].tool[tp.i]   == nil 
			or vehicle.aseChain.nodes[i].tool[tp.i].x == nil 
			or vehicle.aseChain.nodes[i].tool[tp.i].z == nil then
				
		if vehicle.aseChain.nodes[i].tool[tp.i] == nil then
			vehicle.aseChain.nodes[i].tool[tp.i] = {}
		end

		if i == 1 and ( ASEGlobals.shiftFixZ <= 0 or vehicle.aseTools[tp.i].aiForceTurnNoBackward ) then
	
			local x,z
			
			if vehicle.aseLRSwitch then
				x,_,z = AutoSteeringEngine.getRelativeTranslation( vehicle.aseChain.refNode, tp.nodeLeft )	
			else
				x,_,z = AutoSteeringEngine.getRelativeTranslation( vehicle.aseChain.refNode, tp.nodeRight )	
			end
	
			vehicle.aseChain.nodes[i].tool[tp.i].x = x
			vehicle.aseChain.nodes[i].tool[tp.i].z = z
	
		else
			if math.abs( tp.b2 + tp.b3 ) > 1E-4 then
				for j=1,i do
					if vehicle.aseChain.nodes[j].tool[tp.i] == nil then
						vehicle.aseChain.nodes[j].tool[tp.i] = {}
					end
					if vehicle.aseChain.nodes[j].tool[tp.i].a == nil then
						if math.abs( vehicle.aseChain.nodes[j].steering ) < 1E-5 then
							vehicle.aseChain.nodes[j].tool[tp.i].a = 0
						else
							local r2 = math.sqrt( math.abs( vehicle.aseChain.nodes[j].radius * vehicle.aseChain.nodes[j].radius + tp.b1 * tp.b1 - tp.b2 * tp.b2 ) )
							local r3 = math.sqrt( math.abs( vehicle.aseChain.nodes[j].radius * vehicle.aseChain.nodes[j].radius + tp.b1 * tp.b1 - tp.b2 * tp.b2 - tp.b3 * tp.b3 ) )
							local aa = math.atan( tp.b2 / r2 ) + math.atan( tp.b3 / r3 ) + math.atan( tp.b1 / math.abs(vehicle.aseChain.nodes[j].radius) )
							if vehicle.aseChain.nodes[j].radius > 0 then aa = -aa end
							vehicle.aseChain.nodes[j].tool[tp.i].a = aa
						end
					end
				end
			end
			
			if vehicle.aseLRSwitch ~= nil and ( tp.b1 < 0 or math.abs( tp.b2 + tp.b3 ) > 1E-3 ) then
				if math.abs( tp.b2 + tp.b3 ) > 1E-3 then
					local a=0
					for j=1,ASEGlobals.offtracking do
						jj = i - j
						if jj < 1 then
							a = a + tp.angle
						else
							a = a + vehicle.aseChain.nodes[jj].tool[tp.i].a
						end
					end
					a = a / ASEGlobals.offtracking

					setRotation(    vehicle.aseChain.tNode[1], 0, -a, 0 )
					setTranslation( vehicle.aseChain.tNode[1], 0, 0, tp.b1 )
					setTranslation( vehicle.aseChain.tNode[2], tpx, 0, tp.z-tp.b1 )
					local xt,_,zt = AutoSteeringEngine.getRelativeTranslation( vehicle.aseChain.tNode[0], vehicle.aseChain.tNode[2] )
				
					dx = tpx - xt
					dz = zt - tp.z
				elseif ASEGlobals.limitOutside <= 0 and i > 1 then
					--aRef = vehicle.aseChain.nodes[i-1].steering
					--
					--if vehicle.aseLRSwitch then 
					--	aRef = math.max( aRef, vehicle.aseChain.nodes[i].steering )
					--else 
					--	aRef = math.min( aRef, vehicle.aseChain.nodes[i].steering )
					--end
					--
					--
					--if math.abs(aRef) > 1E-5 then
					--	if ( vehicle.aseLRSwitch and aRef > 0 ) or ( ( not vehicle.aseLRSwitch ) and aRef < 0 ) then
					--		invert = false
					--	else
					--		invert = true
					--	end
					--
					--	local r  = vehicle.aseChain.wheelBase / math.tan( math.abs(aRef) )
					--
					--	if invert then
					--		r = r + tpx
					--	else
					--		r = r - tpx
					--	end			
					--	dx = math.sqrt( r*r + tp.b1*tp.b1 ) - r		
					--end
					--
					--if invert then dx = -dx end
				----else
				----	if vehicle.aseLRSwitch then
				----		tpx = tpx + tp.offset 
				----	else 
				----		tpx = tpx - tp.offset 
				----	end 
					if i == 1 then
						aRef = vehicle.aseSteeringAngle
					else
						aRef = vehicle.aseChain.nodes[i-1].steering
					end
				
					if math.abs(aRef) > 1E-5 then
						if ( vehicle.aseLRSwitch and aRef > 0 ) or ( ( not vehicle.aseLRSwitch ) and aRef < 0 ) then
							invert = false
						else
							invert = true
						end
					
						local r  = vehicle.aseChain.wheelBase / math.tan( math.abs(aRef) )
						local r1 = math.sqrt( r*r + tp.b1*tp.b1 )
					
						if invert then
							r = r + tpx
						else
							r = r - tpx
						end			
						dx = math.sqrt( r*r + tp.b1*tp.b1 ) - r		
					end
					
					if invert then dx = -dx end
				end	
			end
			
			if vehicle.aseLRSwitch then
				if dx > 0 then dx = math.max(0,dx-tp.offset) end
			else 
				if dx < 0 then dx = math.min(0,dx+tp.offset) end
			end 

			vehicle.aseChain.nodes[i].tool[tp.i].x = tpx - dx
			vehicle.aseChain.nodes[i].tool[tp.i].z = tp.z + dz
		end
		
		vehicle.aseChain.nodes[i].status = ASEStatus.position
	end
	
	return vehicle.aseChain.nodes[i].tool[tp.i].x, vehicle.aseChain.nodes[i].tool[tp.i].z
	
end

------------------------------------------------------------------------
-- getChainBorder
------------------------------------------------------------------------
function AutoSteeringEngine.getChainBorder( vehicle, i1, i2, toolParam, noBreak )
	if not vehicle.isServer then return 0,0 end
	
	local b,t    = 0,0
	local bo,to  = 0,0
	local d      = false
	local i      = i1
	local count  = 0
	local offsetOutside = -1
	
	if vehicle.aseLRSwitch	then
		offsetOutside = 1
	end

	local fcOffset = -offsetOutside * toolParam.width
	local detectedBefore = false
	
	if 1 <= i and i <= ASEGlobals.chainMax then
		local x,z      = AutoSteeringEngine.getChainPoint( vehicle, i, toolParam )
		local xp,yp,zp = localToWorld( vehicle.aseChain.nodes[i].index,   x, 0, z )
		
		while i<=i2 and i<=ASEGlobals.chainMax do			
			
			x,z            = AutoSteeringEngine.getChainPoint( vehicle, i+1, toolParam )
			local x2,y2,z2 = localToWorld( vehicle.aseChain.nodes[i+1].index, x, 0, z )
			local xc       = x2
			local yc       = y2
			local zc       = z2
			
			if vehicle.aseChain.nodes[i].tool[toolParam.i] == nil then
				AutoTractor.printCallstack()
				AITractor.stopAITractor(vehicle)
			end
			
			if      vehicle.aseChain.nodes[i].tool[toolParam.i].b ~= nil
					and vehicle.aseChain.nodes[i].tool[toolParam.i].t ~= nil then
					
				if vehicle.aseChain.nodes[i].tool[toolParam.i].t >= 0 then
					vehicle.aseChain.nodes[i].isField = true
					b = b + vehicle.aseChain.nodes[i].tool[toolParam.i].b
					t = t + vehicle.aseChain.nodes[i].tool[toolParam.i].t
										
					if b > 0 then
					--d = true
						vehicle.aseChain.nodes[i].hasBorder = true
					elseif not d then
						local wMax = ASEGlobals.maxDetectWidth2
						if      math.abs( wMax - ASEGlobals.maxDetectWidth ) < 0.1
								and vehicle.aseChain.radius ~= nil
								and not ( vehicle.aseTools[toolParam.i].aiForceTurnNoBackward )
								and math.abs( toolParam.x ) < vehicle.aseChain.radius then
							wMax = ASEGlobals.maxDetectWidth
						end
						if wMax > 0 then
							local w = math.min( toolParam.width, wMax )
							if AutoSteeringEngine.getFruitArea( vehicle, xp, zp, xc, zc, -offsetOutside * w, toolParam.i )	> 0	then
								d = true
							--vehicle.aseChain.nodes[i].hasBorder = true
							end
						end
					end
				end
				
			else
				vehicle.aseChain.nodes[i].tool[toolParam.i].b = 0
				vehicle.aseChain.nodes[i].tool[toolParam.i].t = -1
				
				if      not AutoSteeringEngine.hasCollision( vehicle, vehicle.aseChain.nodes[i].index )
						and not AutoSteeringEngine.hasCollision( vehicle, vehicle.aseChain.nodes[i+1].index )
						and AutoSteeringEngine.isChainPointOnField( vehicle, xp, zp ) then
						
					local f = 1
					local c = false
					while f > 0.01 do
						xc = xp + f*(x2-xp)
						yc = yp + f*(y2-yp)
						zc = zp + f*(z2-zp)
						if AutoSteeringEngine.isChainPointOnField( vehicle, xc, zc ) then
							c = true
							break
						end
						f = f - 0.334
					end
						
					if c then
					
						vehicle.aseChain.nodes[i].isField = true
						count = count + 1
						local bi, ti  = AutoSteeringEngine.getFruitArea( vehicle, xp, zp, xc, zc, offsetOutside, toolParam.i )			

						b = b + bi
						t = t + ti
						
						if b > 0 then
						--d = true
							vehicle.aseChain.nodes[i].hasBorder = true
						elseif not d then
							local wMax = ASEGlobals.maxDetectWidth2
							if      math.abs( wMax - ASEGlobals.maxDetectWidth ) < 0.1
									and vehicle.aseChain.radius ~= nil
									and not ( vehicle.aseTools[toolParam.i].aiForceTurnNoBackward )
									and math.abs( toolParam.x ) < vehicle.aseChain.radius then
								wMax = ASEGlobals.maxDetectWidth
							end
							if wMax > 0 then
								local w = math.min( toolParam.width, wMax )
								if AutoSteeringEngine.getFruitArea( vehicle, xp, zp, xc, zc, -offsetOutside * w, toolParam.i )	> 0	then
									d = true
								--vehicle.aseChain.nodes[i].hasBorder = true
								end
							end
						end

						vehicle.aseChain.nodes[i].tool[toolParam.i].b = bi
						vehicle.aseChain.nodes[i].tool[toolParam.i].t = ti
					end
				end
			end
				
			i = i + 1
			xp = x2
			yp = yc
			zp = z2
		end
	end
	
	return b, t, bo, to, d
end

------------------------------------------------------------------------
-- getAllChainBorders
------------------------------------------------------------------------
function AutoSteeringEngine.getAllChainBorders( vehicle, i1, i2, noBreak )
	if not vehicle.isServer then return 0,0 end
	
	local b,t,bo,to = 0,0,0,0
	local d = false
	
	if i1 == nil then i1 = 1 end
	if i2 == nil then i2 = ASEGlobals.chainMax end
	
	local i      = i1
	if 1 <= i and i <= ASEGlobals.chainMax then
		while i<=i2 and i<=ASEGlobals.chainMax do				
			vehicle.aseChain.nodes[i].hasBorder = false
			i = i + 1
		end
	end
		
	for _,tp in pairs(vehicle.aseToolParams) do	
		if tp.skip then
			--nothing
		else
			local bi,ti,boi,toi, di = AutoSteeringEngine.getChainBorder( vehicle, i1, i2, tp )				
			b  = b  + bi
			t  = t  + ti
			bo = bo + boi
			to = to + toi
			if di then d = true end
		end
	end
	
	if to > 0 then
		b = b + bo / to
	  t = t + 1
	end
	
	return b,t,d
end

------------------------------------------------------------------------
-- getSteeringParameterOfTool
------------------------------------------------------------------------
function AutoSteeringEngine.getSteeringParameterOfTool( vehicle, toolIndex, maxLooking, widthOffset, widthFactor )
	
	local toolParam = {}
	toolParam.i       = toolIndex

	local tool = vehicle.aseTools[toolIndex]
	local maxAngle, minAngle
	local xl = -999
	local xr = 999
	local zb = 999
	local il, ir, ib, i1, zl, zr	
	
	if tool.aiForceTurnNoBackward then
		local x0, z0
	
--  no reverse allowed	
		local xOffset,_,zOffset = AutoSteeringEngine.getRelativeTranslation( tool.steeringAxleNode, tool.refNode )
		if tool.aiBackMarker ~= nil then
			_,_,zb = AutoSteeringEngine.getRelativeTranslation( tool.steeringAxleNode, tool.aiBackMarker )
			if zb == nil then zb = 0 end			
			zb = zb - zOffset
		end
		
		for i=1,table.getn(tool.marker) do
			local xxx,_,zzz = AutoSteeringEngine.getRelativeTranslation( tool.steeringAxleNode, tool.marker[i] )
			xxx = xxx - xOffset
			zzz = zzz - zOffset
			if tool.invert then xxx = -xxx zzz = -zzz end
			if xl < xxx then xl = xxx zl = zzz il = i end
			if xr > xxx then xr = xxx zr = zzz ir = i end
			-- back marker!
			if zb > zzz then zb = zzz ib = i end
		end
		
		local width  = xl - xr		
		local offset = AutoSteeringEngine.getWidthOffset( vehicle, width, widthOffset, widthFactor )

		width = width - offset - offset

		if vehicle.aseLRSwitch	then
	-- left	
			x0 = xl - offset
			z0 = zl
			i1 = il
		else
	-- right	
			x0 = xr + offset
			z0 = zr
			i1 = ir
		end
		
		local x1,_,z1 = AutoSteeringEngine.getRelativeTranslation( vehicle.aseChain.refNode, tool.refNode )
				
		x1 = x1 + x0
		z1 = z1 + z0
		toolParam.zReal = z1
		
	--if vehicle.aseDebugTimer == nil or vehicle.aseDebugTimer < g_currentMission.time then
	--	vehicle.aseDebugTimer = g_currentMission.time + 1000		
	--	print(string.format("l: %1.2f r: %1.2f o: %1.2f xo: %1.2f zo: %1.2f x1: %1.2f z1: %1.2f", xl, xr, offset, xOffset, zOffset, x1, z1 ) )
	--end
		
		local b1,b2,b3 = z1, 0, 0

		local r1 = math.sqrt( x1*x1 + b1*b1 )		
		r1       = ( 1 + ASEGlobals.minMidDist ) * ( r1 + math.max( 0, -b1 ) )
		local a1 = math.atan( vehicle.aseChain.wheelBase / r1 )
		
		local toolAngle = 0
	
		if b1 < 0 then
			local _,_,z4  = AutoSteeringEngine.getRelativeTranslation( vehicle.aseChain.refNode, tool.refNode )
			b1 = z4 -- + 0.4
			
			if tool.b1 ~= nil then
				b1 = b1 + tool.b1
			end
			
			if tool.b2 == nil then
				local x3,_,z3 = AutoSteeringEngine.getRelativeTranslation( tool.steeringAxleNode ,tool.marker[i1] )
				if tool.invert then x3 = -x3 z3=-z3 end				
				local _,_,z5  = AutoSteeringEngine.getRelativeTranslation( tool.marker[i1] ,tool.aiBackMarker )
				if tool.invert then z5=-z5 end								
				b2 = z3 - zOffset + 0.5 * z5
			else
				b2 = tool.b2
			end
			
			if b1 < 0 and b2 < -1 then
				b2 = b2 + 0.5
				b1 = b1 - 0.5
			end
			
			if tool.b3 ~= nil then
				b3 = tool.b3
			end
			
			toolAngle = AutoSteeringEngine.getRelativeYRotation( vehicle.aseChain.refNode, tool.steeringAxleNode )
			if tool.invert then
				if toolAngle < 0 then
					toolAngle = toolAngle + math.pi
				else
					toolAngle = toolAngle - math.pi
				end
			end
			
			if tool.doubleJoint then
				toolAngle = toolAngle + toolAngle
			end

		--z1 = 0.5 * ( b1 + z1 )
		end

		toolParam.x        = x1
		toolParam.z        = z1
		toolParam.zBack    = zb
		toolParam.nodeBack = tool.marker[ib]
		toolParam.nodeLeft = tool.marker[il]
		toolParam.nodeRight= tool.marker[ir]
		toolParam.b1       = b1
		toolParam.b2       = b2
		toolParam.b3       = b3
		toolParam.offset   = offset
		toolParam.width    = width
		toolParam.angle    = toolAngle
		toolParam.minRaduis= r1
		toolParam.refAngle = Utils.clamp( a1, ASEGlobals.minLooking, maxLooking )
		toolParam.refAngle2= maxLooking

	else
		local x1
		local z1 = -999
	
--  normal tool, can be lifted and reverse is possible
		if tool.aiBackMarker ~= nil then
			_,_,zb = AutoSteeringEngine.getRelativeTranslation( vehicle.aseChain.refNode, tool.aiBackMarker )
		end
		
		for i=1,table.getn(tool.marker) do
			local xxx,_,zzz = AutoSteeringEngine.getRelativeTranslation( vehicle.aseChain.refNode, tool.marker[i] )
			if xl < xxx then xl = xxx il = i end
			if xr > xxx then xr = xxx ir = i end
			if z1 < zzz then z1 = zzz end
			-- back marker!
			if zb > zzz then zb = zzz ib = i end
		end

		local width  = xl - xr
		local offset = AutoSteeringEngine.getWidthOffset( vehicle, width, widthOffset, widthFactor )

		width = width - offset - offset

		if vehicle.aseLRSwitch	then
	-- left	
			x1 = xl - offset
			i1 = il
		else
	-- right	
			x1 = xr + offset
			i1 = ir
		end

		toolParam.zReal = z1

		local r1 = math.sqrt( x1*x1 + z1*z1 )		
		r1       = ( 1 + ASEGlobals.minMidDist ) * ( r1 + math.max( 0, -z1 ) )
		local a1 = math.atan( vehicle.aseChain.wheelBase / r1 )
		local a2 = maxLooking * ASEGlobals.angleInsideFactor
		
		if z1 < 0 and ( ASEGlobals.limitOutside > 0 or ASEGlobals.limitInside > 0 ) then
			local r2 = 1E+6
			if offset > 0 then
				local of = offset
				local zf = z1 + 0.1 * ( zb-z1 )
				r2 = ( zf*zf - of*of ) / ( of+of )
				if vehicle.aseLRSwitch then
					r2 = r2 + xl
				else
					r2 = r2 - xr
				end
				--print(tostring(r1).." "..tostring(r2).." "..tostring(z1).." "..tostring(offset).." "..tostring(x1))
				if r2 < r1 then
					r2 = r1
				end
			end
			
			if     ASEGlobals.limitInside  > 0 and ASEGlobals.limitOutside > 0 then
				a2 = Utils.clamp(  math.atan( vehicle.aseChain.wheelBase / r2 ), ASEGlobals.minLooking, a2 )
				a1 = math.min( a1, a2 )
			elseif ASEGlobals.limitOutside > 0 then
				a1 = Utils.clamp(  math.atan( vehicle.aseChain.wheelBase / r2 ), ASEGlobals.minLooking, a1 )
			end
		end
		
		
		--print(tostring(math.deg(a1)))
		
		--if tool.isPlough then
			--a1 = 0.5 * a1
		--elseif z1 < 0 and vehicle.aseRealSteeringAngle ~= nil then			
		if ASEGlobals.shiftFixZ > 0 and z1 < 0 and vehicle.aseRealSteeringAngle ~= nil then			
			if math.abs( vehicle.aseRealSteeringAngle ) > 1E-4 then
				local rr, xx, bb
				if vehicle.aseRealSteeringAngle > 0 then
					xx = x1
				else
					xx = -x1
				end				
				rr = vehicle.aseChain.wheelBase / math.tan( math.abs( vehicle.aseRealSteeringAngle ) )
				if 0 < xx and xx < rr then
					bb = math.atan( -z1 / ( rr - xx ) )
				else
					bb = math.asin( -z1 / rr )
				end
								
				xx = rr * ( 1 - math.cos( bb ) )
				if vehicle.aseRealSteeringAngle > 0 then
					x1 = x1 + xx
				else
					x1 = x1 - xx
				end
				z1 = z1 + rr * math.sin( bb ) 
			else
				z1 = 0
			end
		end

		toolParam.x        = x1
		toolParam.z        = z1
		toolParam.zBack    = zb
		toolParam.nodeBack = tool.marker[ib]
		toolParam.nodeLeft = tool.marker[il]
		toolParam.nodeRight= tool.marker[ir]
		toolParam.b1       = z1
		toolParam.b2       = 0
		toolParam.b3       = 0
		toolParam.offset   = offset
		toolParam.width    = width
		toolParam.angle    = 0
		toolParam.minRaduis= r1
		toolParam.refAngle = a1
		toolParam.refAngle2= a2
	
	end

	if vehicle.aseLRSwitch then
		toolParam.minAngle = -math.min(toolParam.refAngle2, maxLooking * ASEGlobals.angleInsideFactor )
		toolParam.maxAngle = math.min( toolParam.refAngle,  maxLooking * ASEGlobals.angleOutsideFactor)
	else
		toolParam.minAngle = -math.min(toolParam.refAngle,  maxLooking * ASEGlobals.angleOutsideFactor)
		toolParam.maxAngle = math.min( toolParam.refAngle2, maxLooking * ASEGlobals.angleInsideFactor )
	end

	-- width is always left - right 
	if vehicle.aseLRSwitch then
	-- toolParam.x is left marker (the biggest one) => l - ( l - r ) = l - l + r = r
		toolParam.xOther = toolParam.x - toolParam.width
	else
	-- toolParam.x is right marker => r + l - r = l
		toolParam.xOther = toolParam.x + toolParam.width
	end
	
	return toolParam
end

------------------------------------------------------------------------
-- setChainStatus
------------------------------------------------------------------------
function AutoSteeringEngine.setChainStatus( vehicle, startIndex, newStatus )
	if not vehicle.isServer then return end
	
	if vehicle.aseChain ~= nil and vehicle.aseChain.nodes ~= nil then
		local i = math.max(startIndex,1)
		while i <= ASEGlobals.chainMax + 1 do
			if vehicle.aseChain.nodes[i].status > newStatus then
				vehicle.aseChain.nodes[i].status = newStatus
			end
			i = i + 1
		end
	end
end

------------------------------------------------------------------------
-- initSteering
------------------------------------------------------------------------
function AutoSteeringEngine.initSteering( vehicle )

	local mi = vehicle.aseMinAngle 
	local ma = vehicle.aseMaxAngle

	if vehicle.aseToolParams == nil or table.getn( vehicle.aseToolParams ) < 1 then
		vehicle.aseMinAngle = -vehicle.aseChain.maxSteering
		vehicle.aseMaxAngle = vehicle.aseChain.maxSteering
		vehicle.aseWidth    = 0
		vehicle.aseDistance = 0
		vehicle.aseStart    = 0
		vehicle.aseActiveX  = 0
		vehicle.aseOtherX   = 0
		vehicle.aseOffset   = 0
		vehicle.aseBack     = 0
  else
		vehicle.aseMinAngle = nil
		vehicle.aseMaxAngle = nil
		vehicle.aseActiveX  = nil
		vehicle.aseOtherX   = nil
		
		vehicle.aseWidth    = 0
		vehicle.aseDistance = nil
		vehicle.aseStart    = nil
		vehicle.aseOffset   = nil
		vehicle.aseBack     = nil 
		
		for _,tp in pairs(vehicle.aseToolParams) do							
			if vehicle.aseDistance  == nil or vehicle.aseDistance > tp.zReal then
				vehicle.aseDistance  = tp.zReal
			end
			if vehicle.aseStart  == nil or vehicle.aseStart < tp.zReal then
				vehicle.aseStart  = tp.zReal
			end
			if vehicle.aseOffset == nil then
				vehicle.aseOffset = tp.offset
			end
			local z = 0
			if vehicle.aseTools[tp.i].isPlough then
				z = math.min( tp.zReal, tp.zBack ) - tp.z
			end
			if vehicle.aseBack == nil or vehicle.aseBack > z then
				vehicle.aseBack = z
			end
			
			local noSkipA = not ( tp.skip )
			local noSkipO = not ( tp.skipOther )
			
			if noSkipA then
				if vehicle.aseMinAngle == nil or vehicle.aseMinAngle < tp.minAngle then
					vehicle.aseMinAngle = tp.minAngle
				end
				if vehicle.aseMaxAngle == nil or vehicle.aseMaxAngle > tp.maxAngle then
					vehicle.aseMaxAngle = tp.maxAngle
				end
			end
			
			if vehicle.aseLRSwitch then
				if noSkipA and ( vehicle.aseActiveX  == nil or vehicle.aseActiveX > tp.x ) then
					vehicle.aseActiveX = tp.x
					vehicle.aseOffset  = tp.offset
				end
				if noSkipO and ( vehicle.aseOtherX  == nil or vehicle.aseOtherX   < tp.xOther ) then
					vehicle.aseOtherX  = tp.xOther 
				end
			else
				if noSkipA and ( vehicle.aseActiveX  == nil or vehicle.aseActiveX < tp.x ) then
					vehicle.aseActiveX = tp.x
					vehicle.aseOffset  = tp.offset 
				end
				if noSkipO and ( vehicle.aseOtherX  == nil or vehicle.aseOtherX   > tp.xOther ) then
					vehicle.aseOtherX  = tp.xOther
				end
			end
		end
  end
	
	if     vehicle.aseActiveX == nil 
			or vehicle.aseOtherX  == nil then
		vehicle.aseWidth   = 0
		vehicle.aseActiveX = 0
		vehicle.aseOtherX  = 0
	elseif vehicle.aseLRSwitch	then
		vehicle.aseWidth = vehicle.aseActiveX - vehicle.aseOtherX
	else
		vehicle.aseWidth = vehicle.aseOtherX - vehicle.aseActiveX
	end
	
	local fixAttacher = false
	for _,tp in pairs(vehicle.aseToolParams) do	
		if      vehicle.aseChain.radius ~= nil
				and not ( tp.skip ) 				
				and not ( vehicle.aseTools[tp.i].aiForceTurnNoBackward )
				and not ( vehicle.aseTools[tp.i].ignoreAI )
				and math.abs( tp.x ) < vehicle.aseChain.radius then
			fixAttacher = true
			break
		end
	end
	
	if not vehicle.aseLRSwitch then vehicle.aseOffset = -vehicle.aseOffset end
	
	if vehicle.aseMinAngle == nil then
		vehicle.aseMinAngle = -vehicle.aseChain.maxSteering
	end
	if vehicle.aseMaxAngle == nil then
		vehicle.aseMaxAngle =  vehicle.aseChain.maxSteering
	end	
	vehicle.aseAngleFactor = AutoSteeringEngine.getAngleFactor( math.max( math.abs( vehicle.aseMinAngle ), math.abs( vehicle.aseMaxAngle ) ) )
	if not vehicle.aseLRSwitch	then
		vehicle.aseAngleFactor = -vehicle.aseAngleFactor
	end 
	
	vehicle.aseChain.nodes = vehicle.aseChain.nodesLow
	if fixAttacher then
		vehicle.aseChain.nodes = vehicle.aseChain.nodesFix
	elseif ASEGlobals.angleFactorNoFix > 0 then
		vehicle.aseAngleFactor = vehicle.aseAngleFactor * ASEGlobals.angleFactorNoFix
	end
	
	if mi == nil or ma == nil or math.abs( vehicle.aseMinAngle - mi ) > 1E-4 or math.abs( vehicle.aseMaxAngle - ma ) > 1E-4 then
		AutoSteeringEngine.setChainStatus( vehicle, 1, ASEStatus.initial )	
		AutoSteeringEngine.applyRotation( vehicle )		
	end

	AutoSteeringEngine.initHeadlandVector( vehicle )	

	if vehicle.aseChain ~= nil and vehicle.aseChain.nodes ~= nil then
		for i=1,ASEGlobals.chainMax do	
			vehicle.aseChain.nodes[i].isField = false
		end	
	end	
	
	vehicle.aseBuffer = {}
end

------------------------------------------------------------------------
-- getChainAngles
------------------------------------------------------------------------
function AutoSteeringEngine.getToolDistance( vehicle )
	if vehicle.aseDistance == nil then
		return 0
	end
	return vehicle.aseDistance
end

------------------------------------------------------------------------
-- getChainAngles
------------------------------------------------------------------------
function AutoSteeringEngine.getChainAngles( vehicle )
	local chainAngles = {}
	
	for j=1,ASEGlobals.chainMax+1 do 
		chainAngles[j] = vehicle.aseChain.nodes[j].angle
	end
	
	return chainAngles
end

------------------------------------------------------------------------
-- setChainAngles
------------------------------------------------------------------------
function AutoSteeringEngine.setChainAngles( vehicle, chainAngles, startIndex, mergeFactor )
	AutoSteeringEngine.setChainInt( vehicle, startIndex, "angles", nil, mergeFactor, chainAngles )
end

------------------------------------------------------------------------
-- setChainStraight
------------------------------------------------------------------------
function AutoSteeringEngine.setChainStraight( vehicle, startIndex, startAngle )	
	AutoSteeringEngine.setChainInt( vehicle, startIndex, "straight", startAngle )
end

------------------------------------------------------------------------
-- setChainOutside
------------------------------------------------------------------------
function AutoSteeringEngine.setChainOutside( vehicle, startIndex, angleSafety, smooth )
	AutoSteeringEngine.setChainInt( vehicle, startIndex, "outside", angleSafety, smooth )
end

------------------------------------------------------------------------
-- setChainContinued
------------------------------------------------------------------------
function AutoSteeringEngine.setChainContinued( vehicle, startIndex )
	AutoSteeringEngine.setChainInt( vehicle, startIndex, "continued" )
end

------------------------------------------------------------------------
-- setChainInside
------------------------------------------------------------------------
function AutoSteeringEngine.setChainInside( vehicle, startIndex )
	AutoSteeringEngine.setChainInt( vehicle, startIndex, "inside" )	
end

------------------------------------------------------------------------
-- setChainInt
------------------------------------------------------------------------
function AutoSteeringEngine.setChainInt( vehicle, startIndex, mode, angle, factor, chainAngles )
	if vehicle.aseChain == nil then
		return
	end
	
	local j0=1
	if startIndex ~= nil and 1 < startIndex and startIndex <= ASEGlobals.chainMax+1 then
		j0 = startIndex
	end

	local a 
	if AutoSteeringEngine.isSetAngleZero( vehicle ) then 
	  a = 0 
	else 
	  a = Utils.getNoNil( vehicle.aseSteeringAngle, 0 )
	end 
	local af = Utils.getNoNil( vehicle.aseAngleFactor, AutoSteeringEngine.getAngleFactor( ) )
	
	local angleSafety = Utils.getNoNil( angle, ASEGlobals.angleSafety )
	
	for j=j0,ASEGlobals.chainMax+1 do 
		local old = vehicle.aseChain.nodes[j].angle

		if     	mode  == "straight" 
				and angle ~= nil
				and j     == j0 then
			vehicle.aseChain.nodes[j].angle = angle
		elseif  mode ~= "straight" 
				and AutoSteeringEngine.isNotHeadland( vehicle, vehicle.aseChain.nodes[j].distance ) then
		
			if     mode == "outside" then
			-- setChainOutside
				vehicle.aseChain.nodes[j].angle = angleSafety 
			elseif mode == "inside" then
			-- setChainInside
				vehicle.aseChain.nodes[j].angle = -ASEGlobals.angleSafety 
			elseif mode == "continued" then
			-- setChainContinued
				vehicle.aseChain.nodes[j].angle = 0
			elseif mode == "angles" then
			-- setChainAngles
				if chainAngles == nil then
					print("Error: AutoSteeringEngine.setChainInt mode angles with empty chainAngles")				
				else
					vehicle.aseChain.nodes[j].angle = Utils.getNoNil( chainAngles[j], 0 )
				end
			else
				print("Error: AutoSteeringEngine.setChainInt wrong mode: "..tostring(mode))				
			end
			
			if factor ~= nil then
				if     mode == "outside" then
					if j <= ASEGlobals.chainMax then
						old = 0.8 * old + 0.2 * vehicle.aseChain.nodes[j+1].angle
					end
					vehicle.aseChain.nodes[j].angle = vehicle.aseChain.nodes[j].angle + factor * ( old - vehicle.aseChain.nodes[j].angle )
					if vehicle.aseChain.nodes[j].angle < 0 then
						vehicle.aseChain.nodes[j].angle = 0
					end
				else
					vehicle.aseChain.nodes[j].angle = vehicle.aseChain.nodes[j].angle + factor * ( old - vehicle.aseChain.nodes[j].angle )
				end			
			end
		elseif math.abs( af ) > 1E-5 and vehicle.aseChain.nodes[j].length > 1E-3 then 
			local targetRot = 0
			if vehicle.acTurnStage ~= nil and vehicle.acTurnStage == 0 then
				targetRot = -AutoSteeringEngine.getTurnAngle( vehicle )				
			elseif j>1 then 
				AutoSteeringEngine.applyRotation( vehicle, j-1 )
				targetRot = Utils.clamp( -Utils.getNoNil( vehicle.aseChain.nodes[j-1].cumulRot, 0 ), -vehicle.aseMaxRotation, vehicle.aseMaxRotation )
			end 
			a = math.atan( 0.5 * math.sin( targetRot ) * vehicle.aseChain.wheelBase / vehicle.aseChain.nodes[j].length )
			vehicle.aseChain.nodes[j].angle = Utils.clamp( a/af , -1, 1 )
		end
		
		if math.abs( vehicle.aseChain.nodes[j].angle - old ) > 1E-5 then
			AutoSteeringEngine.setChainStatus( vehicle, j, ASEStatus.initial )
		end
	end 
	AutoSteeringEngine.applyRotation( vehicle )			
end

------------------------------------------------------------------------
-- getParallelogram
------------------------------------------------------------------------
function AutoSteeringEngine.getParallelogram( xs, zs, xh, zh, diff, noMinLength )
	local xw, zw, xd, zd
	
	xd = zh - zs
	zd = xs - xh
	
	local l = math.sqrt( xd*xd + zd*zd )
	
	if l < 1E-3 then
		xw = xs
		zw = zs
	elseif noMinLength then
	elseif l < ASEGlobals.minLength then
		local f = ASEGlobals.minLength / l
		local x2 = xh - xs
		local z2 = zh - zs
		--xs = xs - f * x2
		--zs = zs - f * z2
		xh = xh + f * x2
		zh = zh + f * z2
		xd = zh - zs
		zd = xs - xh
		l  = math.sqrt( xd*xd + zd*zd )
	end
	
	if 0.999 < l and l < 1.001 then
		xw = xs + diff * xd
		zw = zs + diff * zd
	elseif l > 1E-3 then
		xw = xs + diff * xd / l
		zw = zs + diff * zd / l
	else
		xw = xs
		zw = zs
	end
	
	return xs, zs, xw, zw, xh, zh
end

function AutoSteeringEngine.clearTrace( vehicle )
	vehicle.aseDirectionBeforeTurn = {}
end

------------------------------------------------------------------------
-- invertsMarkerOnTurn
------------------------------------------------------------------------
function AutoSteeringEngine.invertsMarkerOnTurn( vehicle, tool, turnLeft )
	local res = false		
	if tool ~= nil and tool.obj ~= nil then
		for _, spec in pairs(tool.obj.specializations) do		
			if spec.aiInvertsMarkerOnTurn ~= nil then		
				res = res or spec.aiInvertsMarkerOnTurn(tool.obj, turnLeft)		
			end		
		end		
	end		
	return res		
end		

------------------------------------------------------------------------
-- saveDirection
------------------------------------------------------------------------
function AutoSteeringEngine.saveDirection( vehicle, cumulate )

	if vehicle.aseDirectionBeforeTurn == nil then
		vehicle.aseDirectionBeforeTurn = {}
	end

	vehicle.aseDirectionBeforeTurn.a           = nil
	vehicle.aseDirectionBeforeTurn.l           = nil
	vehicle.aseDirectionBeforeTurn.isUTurn     = nil
	vehicle.aseDirectionBeforeTurn.targetTrace = nil
	
	if not ( cumulate ) or vehicle.aseDirectionBeforeTurn.traceIndex == nil or vehicle.aseDirectionBeforeTurn.trace == nil then
		vehicle.aseDirectionBeforeTurn.trace       = {}
		vehicle.aseDirectionBeforeTurn.traceIndex  = 0
		vehicle.aseDirectionBeforeTurn.uTrace      = {}
		vehicle.aseDirectionBeforeTurn.uTraceIndex = 0
		vehicle.aseDirectionBeforeTurn.sx, _, vehicle.aseDirectionBeforeTurn.sz = AutoSteeringEngine.getAiWorldPosition( vehicle )
		vehicle.aseDirectionBeforeTurn.ux          = nil
		vehicle.aseDirectionBeforeTurn.uz          = nil
		vehicle.aseDirectionBeforeTurn.cx          = nil
		vehicle.aseDirectionBeforeTurn.cz          = nil
		vehicle.aseDirectionBeforeTurn.ox          = nil
		vehicle.aseDirectionBeforeTurn.oz          = nil
		vehicle.aseDirectionBeforeTurn.tpBuffer    = {}
	end

	local wx,_,wz = localToWorld( vehicle.aseChain.refNode, vehicle.aseOtherX, 0 , vehicle.aseBack )
	
	local saveTurnPoint = nil
	if vehicle.aseDirectionBeforeTurn.ux == nil then
		saveTurnPoint = true
	elseif Utils.vector2LengthSq( vehicle.aseDirectionBeforeTurn.x - wx, vehicle.aseDirectionBeforeTurn.z - wz ) < 0.01 then
		saveTurnPoint = false
	end
	
	vehicle.aseDirectionBeforeTurn.x = wx
	vehicle.aseDirectionBeforeTurn.z = wz
	
	if vehicle.aseLRSwitch then
		vehicle.aseDirectionBeforeTurn.dx,_,vehicle.aseDirectionBeforeTurn.dz = localDirectionToWorld( vehicle.aseChain.refNode, 1, 0, 0 )
	else
		vehicle.aseDirectionBeforeTurn.dx,_,vehicle.aseDirectionBeforeTurn.dz = localDirectionToWorld( vehicle.aseChain.refNode,-1, 0, 0 )
	end	
	
	local turnXu, turnZc
	local turnZu = vehicle.aseStart
	local turnXc = vehicle.aseOtherX
		
	for i,tp in pairs(vehicle.aseToolParams) do	
		local tpb
		if vehicle.aseDirectionBeforeTurn.tpBuffer[i] == nil then
			vehicle.aseDirectionBeforeTurn.tpBuffer[i] = { xA = tp.x, 
			                                               xO = tp.xOther, 
																										 zR = tp.zReal }
			tpb = vehicle.aseDirectionBeforeTurn.tpBuffer[i]
		else
			tpb = vehicle.aseDirectionBeforeTurn.tpBuffer[i]
			tpb.xA = tpb.xA + 0.05 * ( tp.x      - tpb.xA )
			tpb.xO = tpb.xO + 0.05 * ( tp.xOther - tpb.xO )
			tpb.zR = tpb.zR + 0.05 * ( tp.zReal  - tpb.zR )
		end
		
		local oxr,_,ozr = localToWorld( vehicle.aseChain.refNode, tpb.xO, 0 , tpb.zR )
		
		local ofs, idx
		if vehicle.aseLRSwitch	then
			ofs = tp.offset 
			idx = tp.nodeRight
		else
			ofs = -tp.offset 
			idx = tp.nodeLeft 
		end
		
		local ox,_,oz = localToWorld( idx, ofs, 0, 1 )
		
		if      not ( tp.skipOther and tp.skip ) 
				and ( saveTurnPoint == nil or saveTurnPoint == true )
				and ( ( ( vehicle.aseHeadland >= 1
					  and AutoSteeringEngine.isChainPointOnField( vehicle, ox, oz ) )
				   or ( vehicle.aseHeadland < 1
					  and AutoSteeringEngine.checkField( vehicle, ox, oz ) ) ) ) then
						
			local d = Utils.getNoNil( vehicle.aseDirectionBeforeTurn.lastD, 0.1 ) 
			local stp = false
			if saveTurnPoint then
				stp = true
			end
			
			while not ( stp ) do
				local a, t = AutoSteeringEngine.getFruitAreaWorldPositions( vehicle, vehicle.aseTools[tp.i], ox-d-0.5,oz-d,ox+d+0.5,oz-d,ox-d-0.5,oz+d )
				if a > 0 then
					stp = true
				elseif t > 0 then
					break
				end
				d = d + 0.1
				if d > 1 then
					break
				end
			end
			
			d = d - 0.01
			if     d <= 0.1 then
				vehicle.aseDirectionBeforeTurn.lastD = 0.1
			elseif d >= 0.9 then
				vehicle.aseDirectionBeforeTurn.lastD = 0.9
			else
				vehicle.aseDirectionBeforeTurn.lastD = d
			end				
						
			if stp then			
				saveTurnPoint = true

				vehicle.aseDirectionBeforeTurn.ox = ox
				vehicle.aseDirectionBeforeTurn.oz = oz
				local mx,_,mz = worldDirectionToLocal( vehicle.aseChain.refNode, ox - oxr, 0, oz - ozr )

				if not ( tp.skipOther ) then
					local txu = tpb.xO 				
					if AutoSteeringEngine.invertsMarkerOnTurn( vehicle, vehicle.aseTools[tp.i], not vehicle.aseLRSwitch ) then
						txu = -tpb.xA
					end
					txu = tpb.xO + txu + mx
					
					if     turnXu == nil then
						turnXu = txu 
						turnZu = vehicle.aseStart + mz
					elseif vehicle.aseLRSwitch then
						if turnXu > txu then
							turnXu = txu 
							turnZu = vehicle.aseStart + mz
						end
					else
						if turnXu < txu then
							turnXu = txu 
							turnZu = vehicle.aseStart + mz
						end
					end
				end
				
				if not ( tp.skip ) then
					local tzc = tpb.xA
					if vehicle.aseLRSwitch then
						tzc = -tzc
					end						
					tzc = tzc + tpb.zR + mz
					
					if     turnZc == nil then
						turnZc = tzc
						turnXc = vehicle.aseOtherX + mx
					elseif turnZc < tzc then
						turnZc = tzc
						turnXc = vehicle.aseOtherX + mx
					end
				end
			end
		end
	end
	
	if saveTurnPoint then
		if turnXu == nil and vehicle.aseDirectionBeforeTurn.ux == nil then
			turnXu = vehicle.aseOtherX
			if AITractor.invertsMarkerOnTurn( vehicle, not vehicle.aseLRSwitch ) then
				turnXu = -vehicle.aseActiveX
			end
			turnXu = turnXu + vehicle.aseOtherX
		end
		if turnZc == nil and vehicle.aseDirectionBeforeTurn.cx == nil then
			turnZc = vehicle.aseActiveX
			if vehicle.aseLRSwitch then
				turnZc = -turnZc 
			end
			turnZc = turnZc + vehicle.aseStart + 0.5
		end
		
		if turnXu ~= nil then
		--vehicle.aseDirectionBeforeTurn.ux, _, vehicle.aseDirectionBeforeTurn.uz = localToWorld( vehicle.aseChain.refNode, turnXu, 0, turnZu )
			vehicle.aseDirectionBeforeTurn.ux, _, vehicle.aseDirectionBeforeTurn.uz = localToWorld( vehicle.aseChain.headlandNode, turnXu, 0, turnZu )
		end
		if turnZc ~= nil then
		--vehicle.aseDirectionBeforeTurn.cx, _, vehicle.aseDirectionBeforeTurn.cz = localToWorld( vehicle.aseChain.refNode, turnXc, 0, turnZc )
			vehicle.aseDirectionBeforeTurn.cx, _, vehicle.aseDirectionBeforeTurn.cz = localToWorld( vehicle.aseChain.headlandNode, turnXc, 0, turnZc )
		end
	end
	
	if cumulate then
		local vector = {}	
		vector.dx,_,vector.dz = localDirectionToWorld( vehicle.aseChain.refNode, 0,0,1 )
		vector.px,_,vector.pz = AutoSteeringEngine.getAiWorldPosition( vehicle )
		
		local count = table.getn(vehicle.aseDirectionBeforeTurn.trace)
		if count > 100 and vehicle.aseDirectionBeforeTurn.traceIndex == count then
			local x = vehicle.aseDirectionBeforeTurn.trace[vehicle.aseDirectionBeforeTurn.traceIndex].px - vehicle.aseDirectionBeforeTurn.trace[1].px
			local z = vehicle.aseDirectionBeforeTurn.trace[vehicle.aseDirectionBeforeTurn.traceIndex].pz - vehicle.aseDirectionBeforeTurn.trace[1].pz		
		
			if x*x + z*z > 900 then 
				vehicle.aseDirectionBeforeTurn.traceIndex = 0
			end
		end
		vehicle.aseDirectionBeforeTurn.traceIndex = vehicle.aseDirectionBeforeTurn.traceIndex + 1
		
		vehicle.aseDirectionBeforeTurn.trace[vehicle.aseDirectionBeforeTurn.traceIndex] = vector
	end
end

------------------------------------------------------------------------
-- shiftTurnVector
------------------------------------------------------------------------
function AutoSteeringEngine.shiftTurnVector( vehicle, distance )

	if vehicle.aseDirectionBeforeTurn.dx == nil then
		return 
	end
		
	vehicle.aseDirectionBeforeTurn.ux = vehicle.aseDirectionBeforeTurn.ux + vehicle.aseDirectionBeforeTurn.dx * distance
	vehicle.aseDirectionBeforeTurn.uz = vehicle.aseDirectionBeforeTurn.uz + vehicle.aseDirectionBeforeTurn.dz * distance

	if vehicle.aseLRSwitch then
		vehicle.aseDirectionBeforeTurn.cx = vehicle.aseDirectionBeforeTurn.cx - vehicle.aseDirectionBeforeTurn.dz * distance
		vehicle.aseDirectionBeforeTurn.cz = vehicle.aseDirectionBeforeTurn.cz + vehicle.aseDirectionBeforeTurn.dx * distance
	else
		vehicle.aseDirectionBeforeTurn.cx = vehicle.aseDirectionBeforeTurn.cx + vehicle.aseDirectionBeforeTurn.dz * distance
		vehicle.aseDirectionBeforeTurn.cz = vehicle.aseDirectionBeforeTurn.cz - vehicle.aseDirectionBeforeTurn.dx * distance
	end
	
	AutoSteeringEngine.navigateToSavePoint( vehicle, 0 )
end

------------------------------------------------------------------------
-- getFirstTraceIndex
------------------------------------------------------------------------
function AutoSteeringEngine.getFirstTraceIndex( vehicle )
	if     vehicle.aseDirectionBeforeTurn.trace      == nil 
			or vehicle.aseDirectionBeforeTurn.traceIndex == nil 
			or vehicle.aseDirectionBeforeTurn.traceIndex < 1 then
		return nil
	end
	local l = table.getn(vehicle.aseDirectionBeforeTurn.trace)
	if l < 1 then
		return nil
	end
	local i = vehicle.aseDirectionBeforeTurn.traceIndex + 1
	if i > l then i = 1 end
	return i
end

------------------------------------------------------------------------
-- getTurnVector
------------------------------------------------------------------------
function AutoSteeringEngine.getTurnVector( vehicle, uTurn )
	if     vehicle.aseChain.refNode         == nil
			or vehicle.aseDirectionBeforeTurn   == nil
			or vehicle.aseDirectionBeforeTurn.x == nil
			or vehicle.aseDirectionBeforeTurn.z == nil then
		return 0,0
	end

	if uTurn == nil then
		if vehicle.aseDirectionBeforeTurn.isUTurn == nil then
			return 0,0
		end
		uTurn = vehicle.aseDirectionBeforeTurn.isUTurn
	end
	
	setRotation( vehicle.aseChain.headlandNode, 0, -AutoSteeringEngine.getTurnAngle( vehicle ), 0 )
	
	local _,wy,_ = AutoSteeringEngine.getAiWorldPosition( vehicle )
	local wx, wz
	
	if uTurn then
		wx = vehicle.aseDirectionBeforeTurn.ux
		wz = vehicle.aseDirectionBeforeTurn.uz 
	else
		wx = vehicle.aseDirectionBeforeTurn.cx
		wz = vehicle.aseDirectionBeforeTurn.cz 
	end
	
	local x,y,z = worldToLocal( vehicle.aseChain.headlandNode, wx , wy, wz )
	
	-- change view point...
	x = -x
	
	z = -z
	
	return x,z
end

------------------------------------------------------------------------
-- getToolTurnVector
------------------------------------------------------------------------
function AutoSteeringEngine.getToolTurnVector( vehicle, toolParam )
	if     vehicle.aseChain.refNode          == nil
			or vehicle.aseDirectionBeforeTurn    == nil
			or vehicle.aseDirectionBeforeTurn.ox == nil
			or vehicle.aseDirectionBeforeTurn.oz == nil then
		print("direction not saved")
		return 0,0
	end
	
	setRotation( vehicle.aseChain.headlandNode, 0, -AutoSteeringEngine.getTurnAngle( vehicle ), 0 )

	local node, ofs    
	if vehicle.aseLRSwitch then
		node = toolParam.nodeLeft
		ofs  = -toolParam.offset
	else
		node = toolParam.nodeRight
		ofs  = toolParam.offset
	end
	local _,wy,_   = AutoSteeringEngine.getAiWorldPosition( vehicle )
	local wx       = vehicle.aseDirectionBeforeTurn.ox
	local wz       = vehicle.aseDirectionBeforeTurn.oz
	local ox,_,oz  = worldToLocal( vehicle.aseChain.headlandNode, wx , wy, wz )
	local tx,_,tz  = AutoSteeringEngine.getRelativeTranslation( vehicle.aseChain.headlandNode, node )
	local dx,dy,dz = localDirectionToWorld( vehicle.aseTools[toolParam.i].steeringAxleNode, ofs, 0, 0 )
	dx,dy,dz       = worldDirectionToLocal( vehicle.aseChain.headlandNode, dx, dy, dz )
	
	return ox-(tx+dx), oz-(tz+dz)
end

------------------------------------------------------------------------
-- getToolsTurnVector
------------------------------------------------------------------------
function AutoSteeringEngine.getToolsTurnVector( vehicle )
	local xMin, xMax, zMin, zMax
	
	if vehicle.aseToolParams == nil then
		return 0, 0, 0, 0
	end
	
	for _,tp in pairs( vehicle.aseToolParams ) do
		if not ( tp.skip ) then
			local tx,tz = AutoSteeringEngine.getToolTurnVector( vehicle, tp )
			
			if xMin == nil or xMin > tx then xMin = tx end
			if xMax == nil or xMax < tx then xMax = tx end
			if zMin == nil or zMin > tz then zMin = tz end
			if zMax == nil or zMax < tz then zMax = tz end
		end
	end
	
	if xMin == nil then xMin = 0 end
	if xMax == nil then xMax = 0 end
	if zMin == nil then zMin = 0 end
	if zMax == nil then zMax = 0 end
	
	return xMin, xMax, zMin, zMax
end

------------------------------------------------------------------------
-- rotateHeadlandNode
------------------------------------------------------------------------
function AutoSteeringEngine.rotateHeadlandNode( vehicle )

	setRotation( vehicle.aseChain.headlandNode, 0, -AutoSteeringEngine.getTurnAngle( vehicle ), 0 )
	
end

------------------------------------------------------------------------
-- initTurnVector
------------------------------------------------------------------------
function AutoSteeringEngine.initTurnVector( vehicle, uTurn )
	
	if     vehicle.aseChain.refNode         == nil
			or vehicle.aseDirectionBeforeTurn   == nil
			or vehicle.aseDirectionBeforeTurn.x == nil
			or vehicle.aseDirectionBeforeTurn.z == nil then
		return
	end
	
	if vehicle.aseDirectionBeforeTurn.isUTurn ~= nil then
		return
	end
	
	vehicle.aseDirectionBeforeTurn.isUTurn = uTurn
	AutoSteeringEngine.rotateHeadlandNode( vehicle )	
	
	if      vehicle.aseDirectionBeforeTurn.a ~= nil 
			and vehicle.aseTools                 ~= nil 
			and vehicle.aseToolCount             > 0 then	
		if uTurn then
		-- U-turn: shift (ux,uz)
			local offsetOutside = -1	
			if vehicle.aseLRSwitch then
				offsetOutside = -offsetOutside
			end
		
			local dxz, _,dzz  = localDirectionToWorld( vehicle.aseChain.headlandNode, 0, 0, 1 )
			local dxx, _,dzx  = localDirectionToWorld( vehicle.aseChain.headlandNode, 1, 0, 0 )			
			local xw0,zw0,xw1,zw1,xw2,zw2 
			local dist = Utils.clamp( AutoSteeringEngine.getTraceLength( vehicle ), ASEGlobals.ignoreDist + 3, ASEGlobals.maxTurnCheck )
			local f = 0

			xw0 = vehicle.aseDirectionBeforeTurn.ox
			zw0 = vehicle.aseDirectionBeforeTurn.oz
			
			xw1 = xw0 - dist * dxz
			zw1 = zw0 - dist * dzz
			xw2 = xw0 - ASEGlobals.ignoreDist * dxz
			zw2 = zw0 - ASEGlobals.ignoreDist * dzz
		
			vehicle.aseDirectionBeforeTurn.itv1 = { AutoSteeringEngine.getParallelogram( xw1, zw1, xw2, zw2, offsetOutside ) }
			
			f  = offsetOutside * 0.025 * math.abs( vehicle.aseWidth )
			for i = 0,40 do
				xw0 = vehicle.aseDirectionBeforeTurn.ox +f*i*dxx
				zw0 = vehicle.aseDirectionBeforeTurn.oz +f*i*dzx
				
				xw1 = xw0 - dist * dxz
				zw1 = zw0 - dist * dzz
				xw2 = xw0 - ASEGlobals.ignoreDist * dxz
				zw2 = zw0 - ASEGlobals.ignoreDist * dzz
				
				if not AutoSteeringEngine.hasFruitsSimple( vehicle, xw1, zw1, xw2, zw2, offsetOutside ) then			
					break
				end
			end	
			
			vehicle.aseDirectionBeforeTurn.itv2 = { AutoSteeringEngine.getParallelogram( xw1, zw1, xw2, zw2, offsetOutside ) }
			
		--print(string.format("%3.2fm %3.2fm / %3.2fm %3.2fm => %3.2fm %3.2fm", 
		--			vehicle.aseDirectionBeforeTurn.ox,
		--			vehicle.aseDirectionBeforeTurn.oz,
		--			vehicle.aseDirectionBeforeTurn.ux,
		--			vehicle.aseDirectionBeforeTurn.uz,
		--			xw0 - vehicle.aseDirectionBeforeTurn.ox,
		--			zw0 - vehicle.aseDirectionBeforeTurn.oz ) )
						
			vehicle.aseDirectionBeforeTurn.ux = vehicle.aseDirectionBeforeTurn.ux + xw0 - vehicle.aseDirectionBeforeTurn.ox
			vehicle.aseDirectionBeforeTurn.uz = vehicle.aseDirectionBeforeTurn.uz + zw0 - vehicle.aseDirectionBeforeTurn.oz
		
		else
		-- 90°: rotate (cx,cz)

			local a = -AutoSteeringEngine.getTurnAngle( vehicle )
			local t = {}
			for d=-30,30,9 do
				t[d] = {}
				t[d].r = math.rad( d )
				if vehicle.aseLRSwitch then
					t[d].r = -t[d].r
				end
				
				setRotation( vehicle.aseChain.headlandNode, 0, a + t[d].r, 0 )

				t[d].ox,_,t[d].oz = localDirectionToWorld( vehicle.aseChain.headlandNode,0, 0, 1 )

				if vehicle.aseLRSwitch then
					t[d].sx,_,t[d].sz = localDirectionToWorld( vehicle.aseChain.headlandNode,-ASEGlobals.ignoreDist, 0, 0 )
				else
					t[d].sx,_,t[d].sz = localDirectionToWorld( vehicle.aseChain.headlandNode, ASEGlobals.ignoreDist, 0, 0 )
				end
				
				for x=1,10 do
					local dx, dz
					if vehicle.aseLRSwitch then
						dx,_,dz = localDirectionToWorld( vehicle.aseChain.headlandNode,-ASEGlobals.ignoreDist-x, 0, 0 )
					else
						dx,_,dz = localDirectionToWorld( vehicle.aseChain.headlandNode, ASEGlobals.ignoreDist+x, 0, 0 )
					end
					local vx = vehicle.aseDirectionBeforeTurn.ox + dx
					local vz = vehicle.aseDirectionBeforeTurn.oz + dz
					local isOnField = AutoSteeringEngine.checkField( vehicle, vx, vz )
					if t[d].dx == nil or isOnField then
						t[d].dx = dx
						t[d].dz = dz
					end
					if not isOnField then
						break
					end
				end
				
				local xs = vehicle.aseDirectionBeforeTurn.ox + t[d].sx
				local zs = vehicle.aseDirectionBeforeTurn.oz + t[d].sz				
				local xh = xs + t[d].dx
				local zh = zs + t[d].dz
				local xw = xs + t[d].ox
				local zw = zs + t[d].oz
				
				if d == 0 then
					vehicle.aseDirectionBeforeTurn.itv1 = { xs, zs, xw, zw, xh, zh }
				end
				
				t[d].a = 0
				t[d].t = 0
				for _,tp in pairs( vehicle.aseToolParams ) do
					if not tp.skip then
						local ta, tt = AutoSteeringEngine.getFruitAreaWorldPositions( vehicle, vehicle.aseTools[tp.i], xs, zs, xw, zw, xh, zh, true )
						t[d].a = t[d].a + ta
						t[d].t = t[d].t + tt
					end
				end
				
				if t[d].a <= 0 or t[d].t <= 0 then
					t[d].q = 0
				else
					t[d].q = t[d].a / t[d].t 
				end
			end			
			
			local bestQ, bestR, bestD, worstQ
			
			for d,result in pairs( t ) do
				if     bestQ == nil 
						or bestQ > result.q 
						or ( bestQ == result.q and bestD < d ) then
					bestQ = result.q
					bestR = result.r 
					bestD = d
				end
				if     worstQ == nil
						or worstQ < result.q then
					worstQ = result.q
				end
			end
			
			if math.abs( worstQ - bestQ ) > 1e-3 then			
			--print(string.format( "%3d %3d° %s %0.3f %3d %3d", bestD, math.deg(bestR), tostring(vehicle.aseLRSwitch), bestQ, t[bestD].a, t[bestD].t))
				vehicle.aseDirectionBeforeTurn.a = vehicle.aseDirectionBeforeTurn.a + bestR
				
				local xs = vehicle.aseDirectionBeforeTurn.ox + t[bestD].sx
				local zs = vehicle.aseDirectionBeforeTurn.oz + t[bestD].sz				
				local xh = xs + t[bestD].dx
				local zh = zs + t[bestD].dz
				local xw = xs + t[bestD].ox
				local zw = zs + t[bestD].oz
				
				vehicle.aseDirectionBeforeTurn.itv2 = { xs, zs, xw, zw, xh, zh }			
			end
			
			AutoSteeringEngine.rotateHeadlandNode( vehicle )	
		end		
	end
end	

------------------------------------------------------------------------
-- getTurnDistance
------------------------------------------------------------------------
function AutoSteeringEngine.getTurnDistance( vehicle )
	if     vehicle.aseChain.refNode             == nil
			or vehicle.aseDirectionBeforeTurn       == nil
			or vehicle.aseDirectionBeforeTurn.trace == nil 
			or vehicle.aseDirectionBeforeTurn.traceIndex < 1 then
		return 0
	end
	local _,y,_ = AutoSteeringEngine.getAiWorldPosition( vehicle )
	local x,_,z = worldToLocal( vehicle.aseChain.refNode, vehicle.aseDirectionBeforeTurn.trace[vehicle.aseDirectionBeforeTurn.traceIndex].px, y, vehicle.aseDirectionBeforeTurn.trace[vehicle.aseDirectionBeforeTurn.traceIndex].pz )
	return math.sqrt( x*x + z*z )
end

------------------------------------------------------------------------
-- getTurnDistance
------------------------------------------------------------------------
function AutoSteeringEngine.getTurnDistanceSq( vehicle )
	if     vehicle.aseChain.refNode             == nil
			or vehicle.aseDirectionBeforeTurn       == nil
			or vehicle.aseDirectionBeforeTurn.trace == nil 
			or vehicle.aseDirectionBeforeTurn.traceIndex < 1 then
		return 0
	end
	local _,y,_ = AutoSteeringEngine.getAiWorldPosition( vehicle )
	local x,_,z = worldToLocal( vehicle.aseChain.refNode, vehicle.aseDirectionBeforeTurn.trace[vehicle.aseDirectionBeforeTurn.traceIndex].px, y, vehicle.aseDirectionBeforeTurn.trace[vehicle.aseDirectionBeforeTurn.traceIndex].pz )
	return x*x + z*z
end

------------------------------------------------------------------------
-- getTraceLength
------------------------------------------------------------------------
function AutoSteeringEngine.getTraceLength( vehicle )
	if     vehicle.aseChain.refNode         == nil
			or vehicle.aseDirectionBeforeTurn   == nil then
		return 0
	end
	if     vehicle.aseDirectionBeforeTurn.sx    == nil
			or vehicle.aseDirectionBeforeTurn.sz    == nil
			or vehicle.aseDirectionBeforeTurn.trace == nil then
		return 0
	end
	
	if table.getn(vehicle.aseDirectionBeforeTurn.trace) < 2 then
		return 0
	end
		
	local i = AutoSteeringEngine.getFirstTraceIndex( vehicle )
	if i == nil then
		return 0
	end
	
	if vehicle.aseDirectionBeforeTurn.l == nil then
		local x = vehicle.aseDirectionBeforeTurn.trace[vehicle.aseDirectionBeforeTurn.traceIndex].px - vehicle.aseDirectionBeforeTurn.sx
		local z = vehicle.aseDirectionBeforeTurn.trace[vehicle.aseDirectionBeforeTurn.traceIndex].pz - vehicle.aseDirectionBeforeTurn.sz
		vehicle.aseDirectionBeforeTurn.l = math.sqrt( x*x + z*z )
	end
	
	return vehicle.aseDirectionBeforeTurn.l
end

------------------------------------------------------------------------
-- getTurnAngle
------------------------------------------------------------------------
function AutoSteeringEngine.getTurnAngle( vehicle )
	if vehicle.aseBuffer == nil then
		vehicle.aseBuffer = {}
	elseif vehicle.aseBuffer.getTurnAngle ~= nil then
		return vehicle.aseBuffer.getTurnAngle
	end

	if     vehicle.aseChain.refNode         == nil
			or vehicle.aseDirectionBeforeTurn   == nil then
		vehicle.aseBuffer.getTurnAngle = 0
		return 0
	end
	if vehicle.aseDirectionBeforeTurn.a == nil then
		local i = AutoSteeringEngine.getFirstTraceIndex( vehicle )
		if i == nil then
			vehicle.aseBuffer.getTurnAngle = 0
			return 0
		end
		if i == vehicle.aseDirectionBeforeTurn.traceIndex then
			vehicle.aseBuffer.getTurnAngle = 0
			return 0
		end
		local l = AutoSteeringEngine.getTraceLength( vehicle )
		if l < 2 then
			vehicle.aseBuffer.getTurnAngle = 0
			return 0
		end

		local vx = vehicle.aseDirectionBeforeTurn.trace[vehicle.aseDirectionBeforeTurn.traceIndex].px - vehicle.aseDirectionBeforeTurn.trace[i].px
		local vz = vehicle.aseDirectionBeforeTurn.trace[vehicle.aseDirectionBeforeTurn.traceIndex].pz - vehicle.aseDirectionBeforeTurn.trace[i].pz		
		vehicle.aseDirectionBeforeTurn.a = Utils.getYRotationFromDirection(vx,vz)
		
		if vehicle.aseDirectionBeforeTurn.a == nil then
			print("NIL!!!!")
		end
	end

	local x,y,z = localDirectionToWorld( vehicle.aseChain.refNode, 0,0,1 )
	
	local angle = AutoSteeringEngine.normalizeAngle( Utils.getYRotationFromDirection(x,z) - vehicle.aseDirectionBeforeTurn.a )	

	vehicle.aseBuffer.getTurnAngle = angle
	return angle
end	

------------------------------------------------------------------------
-- getRelativeTranslation
------------------------------------------------------------------------
function AutoSteeringEngine.getRelativeTranslation(root,node)
	if root == nil or node == nil then
		if ASEGlobals.devFeatures > 0 then AutoTractor.printCallstack() end
		return 0,0,0
	end
	local x,y,z
	local state,result = pcall( getParent, node )
	if not ( state ) then
		if ASEGlobals.devFeatures > 0 then AutoTractor.printCallstack() end
		return 0,0,0
	elseif result==root then
		x,y,z = getTranslation(node)
	else
		x,y,z = worldToLocal(root,getWorldTranslation(node))
	end
	return x,y,z
end

------------------------------------------------------------------------
-- getRelativeYRotation
------------------------------------------------------------------------
function AutoSteeringEngine.getRelativeYRotation(root,node)
	if root == nil or node == nil then
		AutoTractor.printCallstack()
		return 0
	end
	local x, y, z = worldDirectionToLocal(node, localDirectionToWorld(root, 0, 0, 1))
	local dot = z
	dot = dot / Utils.vector2Length(x, z)
	local angle = math.acos(dot)
	if x < 0 then
		angle = -angle
	end
	return angle
end

------------------------------------------------------------------------
-- getRelativeYRotation
------------------------------------------------------------------------
function AutoSteeringEngine.getRelativeZRotation(root,node)
	if root == nil or node == nil then
		AutoTractor.printCallstack()
		return 0
	end
	local x, y, z = worldDirectionToLocal(node, localDirectionToWorld(root, 0, 1, 0))
	local dot = y
	dot = dot / Utils.vector2Length(x, y)
	local angle = math.acos(dot)
	if x < 0 then
		angle = -angle
	end
	return angle
end

------------------------------------------------------------------------
-- initChain
------------------------------------------------------------------------
function AutoSteeringEngine.initChain( vehicle, iRefNode, zOffset, wheelBase, maxSteering, widthOffset, turnOffset )
	
	vehicle.aseChain = {}
	vehicle.aseChain.resetCounter = AutoSteeringEngine.resetCounter
		
	vehicle.aseChain.length       = ASEGlobals.chainMax * ASEGlobals.chainLen
	if ASEGlobals.chainMax >= 2 and math.abs( ASEGlobals.chainLenInc ) > 1E-3 then
		vehicle.aseChain.length     = vehicle.aseChain.length + 0.5 * ( ASEGlobals.chainMax - 1 ) * ( ASEGlobals.chainMax - 2 ) * ASEGlobals.chainLenInc
	end
	vehicle.aseChain.zOffset      = zOffset
	vehicle.aseChain.wheelBase    = wheelBase
	vehicle.aseChain.invWheelBase = 1 / wheelBase
	vehicle.aseChain.maxSteering  = maxSteering

	if not vehicle.isServer then 
		vehicle.aseChain.refNode = iRefNode
		return 
	end

	vehicle.aseChain.refNode      = createTransformGroup( "acChainRef" )
	link( iRefNode, vehicle.aseChain.refNode )
	setTranslation( vehicle.aseChain.refNode, 0,0, vehicle.aseChain.zOffset )
	vehicle.aseChain.headlandNode = createTransformGroup( "acHeadland" )
	link( vehicle.aseChain.refNode, vehicle.aseChain.headlandNode )

	if ASEGlobals.staticRoot > 0 then
		vehicle.aseChain.rootNode   = createTransformGroup( "acChainRoot" )
		link( g_currentMission.terrainRootNode, vehicle.aseChain.rootNode )
	else
		vehicle.aseChain.rootNode   = vehicle.aseChain.refNode 
	end
	--vehicle.aseChain.otherINode   = createTransformGroup( "acOtherI" )
	--link( vehicle.aseChain.refNode, vehicle.aseChain.otherINode )
	
	for chainType=1,2 do
		local cl0
		local cli
		local clm
		local pre 
		
		if chainType == 1 then
			cl0 = ASEGlobals.chainLen
			cli = ASEGlobals.chainLenInc
			clm = ASEGlobals.chainLenMax
			pre = "acChainA"
		else
			cl0 = ASEGlobals.chain2Len
			cli = ASEGlobals.chain2LenInc
			clm = ASEGlobals.chain2LenMax
			pre = "acChainB"
		end
	
		local node    = {}
		node.index    = createTransformGroup( pre.."0" )
		node.index2   = createTransformGroup( pre.."0_rot" )
		node.status   = 0
		node.angle    = 0
		node.steering = 0
		node.rotation = 0
		node.isField  = false
		node.distance = 0
		node.length   = 0
		node.tool     = {}
		link( vehicle.aseChain.rootNode, node.index )
		link( node.index, node.index2 )

		local distance = 0
		local nodes = {}
		nodes[1] = node
		
		for i=1,ASEGlobals.chainMax do
			local parent   = nodes[i]
			local text     = string.format("%s%i",pre,i)
			local node2    = {}
			local add      = cl0 + ( i-1 ) * cli
			if clm > 0 and add > clm then 
				add = clm
			end
			distance       = distance + add
			node2.index    = createTransformGroup( text )
			node2.index2   = createTransformGroup( text.."_rot" )
			node2.status   = 0
			node2.angle    = 0
			node2.steering = 0
			node2.rotation = 0
			node2.isField  = false
			node2.distance = distance
			node2.length   = 0
			node2.tool     = {}
			
			link( parent.index2, node2.index )
			link( node2.index, node2.index2 )
			setTranslation( node2.index, 0,0,add )
			
			nodes[#nodes].length = add
			
			nodes[#nodes+1] = node2
		end
		
		if chainType == 1 then
			vehicle.aseChain.nodesFix = nodes
		else
			vehicle.aseChain.nodesLow = nodes
		end
	end
	
	vehicle.aseChain.tNode = {}
	
	vehicle.aseChain.tNode[0] = createTransformGroup( "acTJoin" )
	vehicle.aseChain.tNode[1] = createTransformGroup( "acTJoin1" )
	vehicle.aseChain.tNode[2] = createTransformGroup( "acTJoin1" )
	link(vehicle.aseChain.refNode, vehicle.aseChain.tNode[0])
	link(vehicle.aseChain.tNode[0],vehicle.aseChain.tNode[1])
	link(vehicle.aseChain.tNode[1],vehicle.aseChain.tNode[2])
	
end

function AutoSteeringEngine.deleteNode( index, noUnlink )
	return pcall(AutoSteeringEngine.deleteNode1, index, noUnlink )
end

function AutoSteeringEngine.deleteNode1( index, noUnlink )

	if noUnlink then
	else
		unlink( index )
	end
	delete( index )
end

------------------------------------------------------------------------
-- deleteChain
------------------------------------------------------------------------
function AutoSteeringEngine.deleteChain( vehicle )

	AutoSteeringEngine.deleteTools( vehicle )

	if vehicle.aseChain == nil then return end

	local i
	if vehicle.aseChain.nodes ~= nil then
		local n = vehicle.aseChain.nodes
		vehicle.aseChain.nodes = nil
		for j=-1,ASEGlobals.chainMax-1 do
			i = ASEGlobals.chainMax - j
			AutoSteeringEngine.deleteNode( n[i].index2 )
			AutoSteeringEngine.deleteNode( n[i].index  )
		end
	end
	
	if vehicle.aseChain.tNode ~= nil then
		AutoSteeringEngine.deleteNode( vehicle.aseChain.tNode[2] )
		AutoSteeringEngine.deleteNode( vehicle.aseChain.tNode[1] )
		AutoSteeringEngine.deleteNode( vehicle.aseChain.tNode[0], true )
		vehicle.aseChain.tNode = nil 
	end

	if vehicle.aseChain.headlandNode ~= nil then
		AutoSteeringEngine.deleteNode( vehicle.aseChain.headlandNode )
		vehicle.aseChain.headlandNode = nil
	end
	
	if vehicle.aseChain.refNode == nil then
		AutoSteeringEngine.deleteNode( vehicle.aseChain.refNode )
		vehicle.aseChain.refNode = nil
	end
	
	if ASEGlobals.staticRoot > 0 and vehicle.aseChain.rootNode == nil then
		AutoSteeringEngine.deleteNode( vehicle.aseChain.rootNode )
		vehicle.aseChain.rootNode = nil
	end
	
	vehicle.aseChain = nil
	vehicle.aseCurrentField = nil		
	
end

------------------------------------------------------------------------
-- getSpecialToolSettings
------------------------------------------------------------------------
function AutoSteeringEngine.getSpecialToolSettings( vehicle )
	local settings = {}
	
	settings.leftOnly  = false
	settings.rightOnly = false
	
	if not ( vehicle.aseChain ~= nil and vehicle.aseLRSwitch ~= nil and vehicle.aseToolCount ~= nil and vehicle.aseToolCount >= 1 ) then
		return settings
	end
	
	for _,tool in pairs(vehicle.aseTools) do
		if      tool.isPlough then
		--	if     tool.obj.rotationPart               == nil
		--			or tool.obj.rotationPart.turnAnimation == nil then
		--		settings.rightOnly = true
		--	end
		end
		if tool.isCombine then
		--	if tool.xl+tool.xl+tool.xl < -tool.xr then
		--		settings.rightOnly = true
		--	end
		--	if tool.xl > -tool.xr-tool.xr-tool.xr then
		--		settings.leftOnly  = true
		--	end	
		end
	end

	return settings
end

------------------------------------------------------------------------
-- addTool
------------------------------------------------------------------------
function AutoSteeringEngine.addTool( vehicle, implement, object, reference )

	local tool       = {}
	local marker     = {}
	local extraNodes = {}
	
	if implement ~= nil and object == nil then
		object    = implement.object
		reference = implement.object.attacherJoint.node
	end
	
	--if AtResetCounter == nil or AtResetCounter < 1 then
	--	if object.name ~= nil then print("Adding... "..object.name) else print("Adding something") end
	--end
	
	tool.steeringAxleNode   = object.steeringAxleNode
	if tool.steeringAxleNode == nil then
		tool.steeringAxleNode = object.components[1].node
	end
	
	tool.checkZRotation  = false
	
	if 			getName( object.components[1].node ) == "poettingerServo650" 
			and table.getn(object.components)        >= 2 then
		tool.steeringAxleNode = object.components[2].node
		tool.checkZRotation   = true
	end
	
	if tool.checkZRotation then
		local c = getChild( tool.steeringAxleNode, "ASESteeringAxle" )
		if c ~= nil and c > 0 then
			tool.steeringAxleNode = c
		else
			local parent = tool.steeringAxleNode
			tool.steeringAxleNode = createTransformGroup( "ASESteeringAxle" )
			extraNodes[#extraNodes+1] = tool.steeringAxleNode
			link( parent, tool.steeringAxleNode )
		end
	end
	
	local xo,yo,zo = AutoSteeringEngine.getRelativeTranslation( tool.steeringAxleNode, reference )
	
	tool.obj                           = object
	tool.xOffset                       = xo
	tool.zOffset                       = zo
	tool.isAITool                      = false
	tool.specialType                   = ""
	tool.aiTerrainDetailChannel1       = Utils.getNoNil( object.aiTerrainDetailChannel1      ,-1 )
	tool.aiTerrainDetailChannel2       = Utils.getNoNil( object.aiTerrainDetailChannel2      ,-1 )
	tool.aiTerrainDetailChannel3       = Utils.getNoNil( object.aiTerrainDetailChannel3      ,-1 )
	tool.aiTerrainDetailChannel4       = Utils.getNoNil( object.aiTerrainDetailChannel4      ,-1 )
	tool.aiTerrainDetailProhibitedMask = Utils.getNoNil( object.aiTerrainDetailProhibitedMask,0 )
	tool.aiRequiredFruitType           = Utils.getNoNil( object.aiRequiredFruitType          ,FruitUtil.FRUITTYPE_UNKNOWN )
	tool.aiRequiredMinGrowthState      = Utils.getNoNil( object.aiRequiredMinGrowthState     ,0 )
	tool.aiRequiredMaxGrowthState      = Utils.getNoNil( object.aiRequiredMaxGrowthState     ,0 )
	tool.aiProhibitedFruitType         = Utils.getNoNil( object.aiProhibitedFruitType        ,FruitUtil.FRUITTYPE_UNKNOWN )
	tool.aiProhibitedMinGrowthState    = Utils.getNoNil( object.aiProhibitedMinGrowthState   ,0 )
	tool.aiProhibitedMaxGrowthState    = Utils.getNoNil( object.aiProhibitedMaxGrowthState   ,0 )
	tool.b1                            = 0
	tool.b2                            = 0
	tool.b3                            = 0
	tool.invert                        = false
	tool.outTerrainDetailChannel       = -1	
	tool.useAIMarker                   = false
	tool.doubleJoint                   = false
	tool.noRevStraight                 = false
	
	if tool.checkZRotation then
		tool.aiForceTurnNoBackward = true
	elseif  object.aiForceTurnNoBackward then
		tool.aiForceTurnNoBackward = true
	elseif  object.attacherJoint              ~= nil
			and object.attacherJoint.jointType    ~= nil
			and ( object.attacherJoint.jointType  == Vehicle.JOINTTYPE_TRAILERLOW
			   or object.attacherJoint.jointType  == Vehicle.JOINTTYPE_TRAILER ) then
		tool.aiForceTurnNoBackward = true
	elseif object.aiForceTurnNoBackward == nil then
		tool.aiForceTurnNoBackward = false
	end
	
	
	local useAI = true
	tool.isCombine       = SpecializationUtil.hasSpecialization(Combine, object.specializations)
	tool.hasWorkAreas    = SpecializationUtil.hasSpecialization(WorkArea, object.specializations) 
	tool.isTurnOnVehicle = SpecializationUtil.hasSpecialization(TurnOnVehicle, object.specializations)
	tool.isPlough        = SpecializationUtil.hasSpecialization(Plough, object.specializations)
	tool.isCultivator    = SpecializationUtil.hasSpecialization(Cultivator, object.specializations)
	tool.isSowingMachine = SpecializationUtil.hasSpecialization(SowingMachine, object.specializations)
	tool.isSprayer       = SpecializationUtil.hasSpecialization(Sprayer, object.specializations)
	tool.isMower         = SpecializationUtil.hasSpecialization(Mower, object.specializations)
	tool.isFoldable      = SpecializationUtil.hasSpecialization(Foldable, object.specializations)
	
	if tool.isCombine then
		useAI = false
	elseif  object.customEnvironment ~= nil
			and SpecializationUtil.hasSpecialization(SpecializationUtil.getSpecialization( object.customEnvironment ..".HorschSW3500S" ), object.specializations) then 
		useAI = false
  end
	if tool.isPlough and tool.aiForceTurnNoBackward then
		tool.checkZRotation = true
	end

	if		 object.configFileName == "data/vehicles/tools/horsch/horschPronto9SW.xml" then
		tool.doubleJoint = true
		tool.b1 = 0
		tool.b2 = -6
		tool.b3 = -4
	end
	
	tool.ploughTransport = false
	if      tool.isPlough 
			and tool.aiForceTurnNoBackward 
			and tool.obj.rotationPart.turnAnimation ~= nil
			and tool.obj.playAnimation              ~= nil then
		if object.configFileName == "data/vehicles/tools/lemken/lemkenDiamant12.xml" then
			tool.ploughTransport = true
		else
			tool.ploughTransport = ASEGlobals.ploughTransport > 0
		end
	end
		
	if      useAI 
			and object.aiLeftMarker  ~= nil 
			and object.aiRightMarker ~= nil 
			and object.aiLower			 ~= nil
			and object.aiRaise			 ~= nil
			and object.aiTurnOn			 ~= nil
			and object.aiTurnOff		 ~= nil
			then
-- tool with AI support		
		tool.isAITool = true
		tool.useAIMarker = true
		if AtResetCounter == nil or AtResetCounter < 1 then
			--print("object has AI support")
		end
		
		if object.aiLeftMarker ~= nil then
			marker[#marker+1] = object.aiLeftMarker
		end
		
		if object.aiRightMarker ~= nil then
			marker[#marker+1] = object.aiRightMarker
		end
		
		tool.aiBackMarker = object.aiBackMarker		

		if     object.packomatBase ~= nil then
			tool.isPlough = false
			tool.specialType = "Packomat"
			tool.outTerrainDetailChannel = g_currentMission.ploughChannel
		elseif  object.customEnvironment   ~= nil
				and SpecializationUtil.hasSpecialization(SpecializationUtil.getSpecialization( object.customEnvironment ..".Lemken_Gigant" ), object.specializations) then
			tool.outTerrainDetailChannel = g_currentMission.cultivatorChannel
			tool.aiForceTurnNoBackward   = true
		elseif tool.isSowingMachine then
			tool.outTerrainDetailChannel = g_currentMission.sowingChannel
		elseif tool.isCultivator then
			tool.outTerrainDetailChannel = g_currentMission.cultivatorChannel
		elseif tool.isPlough then
			tool.outTerrainDetailChannel = g_currentMission.ploughChannel
			if getName( object.components[1].node ) == "poettingerServo650" then
				tool.specialType = "poettingerServo650"
			end
		end
		
	else
		local areas = nil	
		if     SpecializationUtil.hasSpecialization(Sprayer, object.specializations) then
		-- sprayer	
			if AtResetCounter == nil or AtResetCounter < 1 then
				--print("object is sprayer")
			end
			
			tool.isSprayer                     = true
			tool.aiTerrainDetailChannel1       = g_currentMission.cultivatorChannel
			tool.aiTerrainDetailChannel2       = g_currentMission.sowingChannel
			tool.aiTerrainDetailChannel3       = g_currentMission.sowingWidthChannel
			tool.aiTerrainDetailProhibitedMask = 2 ^ g_currentMission.sprayChannel
			tool.outTerrainDetailChannel       = g_currentMission.sprayChannel
		elseif SpecializationUtil.hasSpecialization(Combine, object.specializations) then
		-- Combine
			if AtResetCounter == nil or AtResetCounter < 1 then
				--print("object is combine")
			end
			
			tool.isCombine = true
			
			if object.aiLeftMarker ~= nil and object.aiRightMarker ~= nil and object.aiBackMarker ~= nil then
				tool.useAIMarker = true
				local tempArea = {}
				tempArea.start  = object.aiLeftMarker
				tempArea.width  = object.aiRightMarker
				tempArea.height = object.aiBackMarker		
				areas    = {}
				areas[1] = tempArea
			end
			
		elseif SpecializationUtil.hasSpecialization(Mower, object.specializations) then
		-- Mower
			if AtResetCounter == nil or AtResetCounter < 1 then
				--print("object is mower")
			end
			
			tool.isMower = true			
			if object.workAreaByType ~= nil then
				areas = object.workAreaByType[8]
			end

		elseif SpecializationUtil.hasSpecialization(FruitPreparer, object.specializations) then
		-- FruitPreparer
			if AtResetCounter == nil or AtResetCounter < 1 then
				--print("object is fruit preparer")
			end
			
			local fruitDesc = FruitUtil.fruitIndexToDesc[object.fruitPreparerFruitType]
			if fruitDesc == nil then return 0 end
			
			if object.workAreaByType ~= nil then
				areas = object.workAreaByType[5]
			end
			
			tool.aiRequiredFruitType        = object.fruitPreparerFruitType
      tool.aiRequiredMinGrowthState   = fruitDesc.minPreparingGrowthState
      tool.aiRequiredMaxGrowthState   = fruitDesc.maxPreparingGrowthState 
		elseif SpecializationUtil.hasSpecialization(Plough, object.specializations) then
		-- Plough
			if AtResetCounter == nil or AtResetCounter < 1 then
				--print("object is plough")
			end
			
			tool.isPlough = true			
			tool.outTerrainDetailChannel = g_currentMission.ploughChannel

		elseif SpecializationUtil.hasSpecialization(Cultivator, object.specializations) then
		-- Cultivator
			if AtResetCounter == nil or AtResetCounter < 1 then
				--print("object is cultivator")
			end
			
			tool.outTerrainDetailChannel = g_currentMission.cultivatorChannel

		elseif SpecializationUtil.hasSpecialization(Tedder, object.specializations) then
		-- Tedder
			if ASEGlobals.devFeatures > 0 and ( AtResetCounter == nil or AtResetCounter < 1 ) then
				print("object is tedder")
			end
			
			tool.isTedder = true			
		
----------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------
elseif ASEGlobals.devFeatures <= 0 then
	return 0
----------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------------------
						
		elseif SpecializationUtil.hasSpecialization(Windrower, object.specializations) then
		-- Windrower
			if ASEGlobals.devFeatures > 0 and ( AtResetCounter == nil or AtResetCounter < 1 ) then
				print("object is windrower")
			end
			
			tool.isWindrower = true			
						
    --------------------------------------------------------
		-- Poettinger X8
		elseif  object.customEnvironment ~= nil
				and SpecializationUtil.hasSpecialization(SpecializationUtil.getSpecialization( object.customEnvironment ..".poettingerX8" ), object.specializations) 
				and object.mowerCutAreasSend ~= nil 
				then

			tool.specialType = "Poettinger X8"
			tool.isMower     = true
			areas = object.mowerCutAreasSend
    --------------------------------------------------------
		-- Poettinger AlphaMotion
		elseif  object.customEnvironment   ~= nil
				and SpecializationUtil.hasSpecialization(SpecializationUtil.getSpecialization( object.customEnvironment ..".poettingerAlpha" ), object.specializations) 
				and object.alpMot              ~= nil
				and object.alpMot.cuttingAreas ~= nil
				then

			tool.specialType = "Poettinger AlphaMotion"
			tool.isMower     = true
			areas = object.alpMot.cuttingAreas
    --------------------------------------------------------
		-- Taarup Mower Cut
		elseif  object.customEnvironment ~= nil
				and ( SpecializationUtil.hasSpecialization(SpecializationUtil.getSpecialization( object.customEnvironment ..".TaarupMowerCut" ), object.specializations) 
				   or SpecializationUtil.hasSpecialization(SpecializationUtil.getSpecialization( object.customEnvironment ..".KevCond240" ), object.specializations)  
				   or SpecializationUtil.hasSpecialization(SpecializationUtil.getSpecialization( object.customEnvironment ..".KevMT" ), object.specializations)  
				   or SpecializationUtil.hasSpecialization(SpecializationUtil.getSpecialization( object.customEnvironment ..".Taarup3532" ), object.specializations) ) 
				and object.mowerCutAreas     ~= nil
				then

			tool.specialType = "Taarup Mower"
			tool.isMower     = true
			areas = object.mowerCutAreas
    --------------------------------------------------------
		elseif  object.customEnvironment ~= nil
				and ( SpecializationUtil.hasSpecialization(SpecializationUtil.getSpecialization( object.customEnvironment ..".HorschSW3500S" ), object.specializations) ) 
				then

			tool.specialType = "Horsch SW3500 S"
			areas = {} --object.cuttingAreas
			local tempArea = {}
			tempArea.start  = object.aiLeftMarker
			tempArea.width  = object.aiRightMarker
		--tempArea.height = object.aiBackMarker		
			tempArea.height = createTransformGroup( "acBackNew" )
			extraNodes[#extraNodes+1] = tempArea.height
			link( tempArea.start, tempArea.height )
			setTranslation( tempArea.height, 0, 0, -4 )
			areas[1] = tempArea
			
			tool.aiForceTurnNoBackward   = true
			tool.isSowingMachine         = true
			tool.outTerrainDetailChannel = g_currentMission.sowingChannel
    --------------------------------------------------------
		else
			return 0
		end
		
		if areas == nil and object.workAreas ~= nil then areas = object.workAreas end
		if areas == nil then return 0 end		

		local zBack 
		
		--print(tostring(table.getn(areas)))
		
		for _, area in pairs(areas) do
			local xx, zz, x1, z1 = 0,0,0,0
			local backIndex      = area.height

			xx,_,z1 = AutoSteeringEngine.getRelativeTranslation( area.start, area.height )
			x1,_,zz = AutoSteeringEngine.getRelativeTranslation( area.start, area.width )
			
			if tool.isCombine or math.abs( xx ) < 1E-2 and zz < 1E-2 then
				marker[#marker+1] = area.start
				marker[#marker+1] = area.width
			elseif math.abs( x1 ) < 1E-2 and z1 < 1E-2 then
				marker[#marker+1] = area.start
				marker[#marker+1] = area.height
				backIndex         = area.width
			else
				marker[#marker+1] = area.start
				marker[#marker+1] = area.width
				marker[#marker+1] = area.height
				marker[#marker+1] = createTransformGroup( "additionalMarker" )
			  extraNodes[#extraNodes+1] = marker[#marker]
				link( area.start, marker[#marker] )
				setTranslation( marker[#marker], xx+x1, 0, zz+z1 )
				if zz < 0 and z1 < 0 then
					backIndex = marker[#marker]
				elseif zz < z1 then
					backIndex = area.width
				end
			end
			
			if backIndex ~= nil then
				local _,_,zzBack = AutoSteeringEngine.getRelativeTranslation( tool.steeringAxleNode, backIndex )
				if zBack == nil or zzBack > zBack then
					zBack = zzBack
					tool.aiBackMarker = backIndex
				end
			end
		end					

		--print(tostring(table.getn(marker)))
	end

	if #marker < 1 then 
		--if AtResetCounter == nil or AtResetCounter < 1 then
		--	print("no marker found") 
		--end
		return 0
	end

	if object.aiBackMarker == nil then
		tool.aiBackMarker = marker[1]
	end
	
	tool.refNode = reference		
	tool.marker  = marker
	
  --------------------------------------------------------
	if      implement              ~= nil
			and object.attacherVehicle ~= nil 
			and object.attacherVehicle == vehicle 
			and AutoSteeringEngine.tableGetN( AutoSteeringEngine.getTaJoints2( vehicle, implement, vehicle.aseChain.refNode, 0 ) ) > 1 then
		tool.doubleJoint = true
	end
	
	----------------------------------------------------------
	---- Vaederstad_SoilMod_Pack
	--
	--if      object.customEnvironment ~= nil 
	--		and object.typeName          == object.customEnvironment..".RapidA" then
	--	if ASEGlobals.devFeatures > 0 then
	--		print(string.sub( object.configFileName, -10, -1 ))
	--	end
	--	if string.sub( object.configFileName, -10, -1 ) ~= "_Light.xml" then
	--		tool.doubleJoint = true
	--	end
	--end
	--
	--if object.customEnvironment ~= nil and object.typeName == object.customEnvironment..".vaederstadTopDown" then
	--	tool.noRevStraight = false
	--end
	--
	---- BioDrill or BioSpray attached to cultivator or seeding machine
	--if      object.customEnvironment                 ~= nil
	--		and object.attacherVehicle                   ~= nil 
	--		and object.attacherVehicle.customEnvironment ~= nil
	--		and object.attacherVehicle.customEnvironment == object.customEnvironment then
	--	if ASEGlobals.devFeatures > 0 then
	--		print(string.sub( object.typeName, -22, -5 ))
	--	end
	--	if     string.sub( object.typeName, -22, -5 ) == "vaederstadBioSpray"
	--			or string.sub( object.typeName, -22, -5 ) == "vaederstadBioDrill" then
	--		tool.ignoreAI = true
	--	end
	--end
 ----------------------------------------------------------
	
  --------------------------------------------------------
	-- tool attached to tool
	if vehicle ~= object.attacherVehicle then
		if vehicle.aseTools == nil then
			return 0
		else
			for i,t in pairs( vehicle.aseTools ) do
				if t.obj == object.attacherVehicle then
					if t.aiForceTurnNoBackward then
						if tool.aiForceTurnNoBackward then
							tool.doubleJoint = true						
						else
							tool.aiForceTurnNoBackward = true
						end
					end
					if t.doubleJoint then
						tool.doubleJoint = true
					end				
					if ( t.isCultivator or t.isSowingMachine ) and tool.isSprayer then
						tool.ignoreAI = true
					end
					
					break
				end
			end
		end
	end
  --------------------------------------------------------
	if     tool.doubleJoint 
			or ( tool.isPlough 
			 and tool.aiForceTurnNoBackward 
			 and not ( tool.ploughTransport ) ) then
		tool.noRevStraight = true
	end
		
	if tool.checkZRotation and tool.steeringAxleNode ~= nil then
		local node = createTransformGroup( "rotSteeringAxleNode" )
	  link( tool.steeringAxleNode, node )
		extraNodes[#extraNodes+1] = node
	end
	
	if table.getn( extraNodes ) > 0 then
		tool.extraNodes = extraNodes
	end
	
		--if object.lengthOffset ~= nil and object.lengthOffset < 0 then			
	if math.abs( AutoSteeringEngine.getRelativeYRotation( vehicle.aseChain.refNode, tool.steeringAxleNode ) ) > 0.6 * math.pi then
	-- wrong rotation ???
		--print("wrong rotation")
		tool.invert = not tool.invert
	end	
	--local _,_,rsz = AutoSteeringEngine.getRelativeTranslation( vehicle.aseChain.refNode, tool.steeringAxleNode )
	--if rsz > 1 then
	--	tool.invert = not tool.invert
	--end		
	
	local xl, xr, zz, zb
	
	for i=1,#marker do
		local x,_,z = AutoSteeringEngine.getRelativeTranslation(tool.steeringAxleNode,marker[i])
		if tool.invert then x = -x end
		if xl == nil or xl < x then xl = x end
		if xr == nil or xr > x then xr = x end
		if zz == nil or zz < z then zz = z end
		if zb == nil or zb > z then zb = z end
	end
	
	tool.xl = xl - tool.xOffset
	tool.xr = xr - tool.xOffset
	tool.z  = zz - tool.zOffset
	tool.zb = zb - tool.zOffset
	
	if tool.doubleJoint then
	-- do nothing
	elseif tool.aiForceTurnNoBackward then
		tool.b1 = AutoSteeringEngine.findComponentJointDistance( vehicle, tool, object )
	
		if object.wheels ~= nil then
			local wna,wza=0,0
			for i,wheel in pairs(object.wheels) do
				local f = AutoSteeringEngine.getToolWheelFactor( vehicle, tool, object, i )
				if f > 1E-3 then
					local _,_,wz = AutoSteeringEngine.getRelativeTranslation(tool.steeringAxleNode,wheel.driveNode)
					wza = wza + f * wz
					wna = wna + f		
				end
			end
			if wna > 0 then
				tool.b2 = wza / wna - tool.zOffset
				if tool.invert then tool.b2 = -tool.b2 end
			--print(string.format("wna=%i wza=%f b2=%f ofs=%f",wna,wza,tool.b2,tool.zOffset))
			end
		end
	else
		tool.b1 = tool.z
	end
	
	local i = 0
	
	if vehicle.aseTools == nil then
		vehicle.aseTools ={}
		i = 1
	else
		i = table.getn(vehicle.aseTools) + 1
	end
	
	if tool.isSprayer and getfenv(0)["modSoilMod2"] ~= nil then
		tool.ignoreAI = true
	end
	
	if not ( tool.ignoreAI ) then
		if tool.isCombine       then vehicle.aseHas.combine       = true end
		if tool.isPlough        then vehicle.aseHas.plough        = true end
		if tool.isCultivator    then vehicle.aseHas.cultivator    = true end
		if tool.isSowingMachine then vehicle.aseHas.sowingMachine = true end
		if tool.isSprayer       then vehicle.aseHas.sprayer       = true end
		if tool.isMower         then vehicle.aseHas.mower         = true end
	end
	
  if tool.isFoldable      then vehicle.aseHas.foldable      = true end                                                       
  if tool.doubleJoint     then vehicle.aseHas.doubleJoint   = true end
  if tool.hasWorkAreas    then vehicle.aseHas.workAreas     = true end
  if tool.isTurnOnVehicle then vehicle.aseHas.turnOnVehicle = true end
		
	if tool.aiForceTurnNoBackward and ( vehicle.aseNoReverseIndex == nil or vehicle.aseNoReverseIndex < 1 ) then 
		vehicle.aseNoReverseIndex = i 
	end 
		
	tool.aiTerrainDetailRequiredMask = AutoSteeringEngine.getTerrainDetailRequiredMask( tool )
	
	vehicle.aseToolCount = i
	vehicle.aseTools[i]  = tool
	return i	
end

------------------------------------------------------------------------
-- isToolWheelRelevant
------------------------------------------------------------------------
function AutoSteeringEngine.getToolWheelFactor( vehicle, tool, object, i )
	return Utils.getNoNil( object.wheels[i].lateralStiffness, 1 )
end

------------------------------------------------------------------------
-- deleteTools
------------------------------------------------------------------------
function AutoSteeringEngine.deleteTools( vehicle )

	if vehicle ~= nil and vehicle.aseTools ~= nil and vehicle.aseToolCount > 0 then
		for _,tool in pairs( vehicle.aseTools ) do
			if tool.extraNodes ~= nil and table.getn( tool.extraNodes ) > 0 then
				for _,n in pairs( tool.extraNodes ) do
					AutoSteeringEngine.deleteNode( n )
				end
			end
		end
	end
	
	vehicle.aseHas            = {}
	vehicle.aseNoReverseIndex = 0
	vehicle.aseToolCount      = 0
	vehicle.aseTools          = nil
end

------------------------------------------------------------------------
-- checkAllowedToDrive
------------------------------------------------------------------------
function AutoSteeringEngine.checkAllowedToDrive( vehicle, checkFillLevel )

	if vehicle.aseCurrentFieldCo ~= nil then
		local x,_,z = AutoSteeringEngine.getAiWorldPosition( vehicle )
		AutoSteeringEngine.checkField( vehicle, x, z )
		if vehicle.aseCurrentFieldCo ~= nil then
			if ASEGlobals.devFeatures > 0 then print("not allowed to drive I") end
			return false
		end
	end
	
  if     not ( vehicle.isMotorStarted ) 
			or ( vehicle.motorStartTime ~= nil and g_currentMission.time <= vehicle.motorStartTime ) then
		if ASEGlobals.devFeatures > 0 then print("not allowed to drive IV") end
		return false
	end

	if vehicle.acIsCPStopped then
		vehicle.acIsCPStopped = false
		if ASEGlobals.devFeatures > 0 then print("not allowed to drive II") end
		return false
	end
	
	if vehicle.aseTools == nil or table.getn(vehicle.aseTools) < 1 then
		if ASEGlobals.devFeatures > 0 then print("not allowed to drive III") end
		return false
	end
	
  local allowedToDrive = true

	for i,tool in pairs(vehicle.aseTools) do
		local self = tool.obj
		local curCapa, maxCapa = 0, 0
		
		if useAIMarker then
			if tool.marker[1] ~= nil then
				tool.marker[1] = tool.obj.aiLeftMarker
			end
			if tool.marker[2] ~= nil then
				tool.marker[2] = tool.obj.aiRightMarker
			end
			tool.aiBackMarker = Utils.getNoNil( tool.obj.aiBackMarker, tool.marker[1] )
		end
		
		if SpecializationUtil.hasSpecialization(Fillable, self.specializations) then
			maxCapa = self:getCapacity()  --Utils.getNoNil( self.capacity, 0 )
			curCapa = self:getFillLevel() --Utils.getNoNil( self.fillLevel, 0 )
			if self.fillLevel ~= nil and curCapa < self.fillLevel then 
				curCapa = self.fillLevel
			end
		end
		
		if  tool.isCombine then -- and tool.obj.isThreshing then
			if tool.waitForDischargeTime == nil then	
				tool.waitForDischargeTime = 0 
			end 
			if tool.waitingForDischarge  == nil then 
				tool.waitingForDischarge  = false 
			end 
			if tool.waitingForTrailerToUnload == nil then 
				tool.waitingForTrailerToUnload = false 
			end 
			
			if maxCapa > 0 and curCapa > maxCapa * 0.1 and self.pipeIsUnloading then
				tool.waitingForDischarge = true
				tool.waitForDischargeTime = g_currentMission.time + vehicle.acDeltaTimeoutStart
			elseif  (curCapa > 0 or maxCapa <= 0) 
					and ( next(self.overloadingTrailersInRange) ~= nil or curCapa >= maxCapa * 0.8 ) then
				do
					local pipeState = Overloading.getOverloadingTrailerInRangePipeState(self)
					if pipeState > 0 then
						Overloading.setPipeState(self,pipeState)
					else
						Overloading.setPipeState(self,2)
					end
					if      maxCapa > 0
							and ( curCapa >= maxCapa or ( curCapa >= maxCapa * 0.8 and next(self.overloadingTrailersInRange) ~= nil ) ) then
						tool.waitingForDischarge = true
						tool.waitForDischargeTime = g_currentMission.time + vehicle.acDeltaTimeoutStart
					elseif next(self.overloadingTrailersInRange) == nil then
						tool.waitingForDischarge = false
					end
				end
			elseif tool.waitingForDischarge and ( curCapa <= 0 or tool.waitForDischargeTime <= g_currentMission.time ) then
				tool.waitingForDischarge = false
				if next(self.overloadingTrailersInRange) == nil then
					Overloading.setPipeState(self,1)
				end
			end
				
			if maxCapa <= 0 then
				if not self.pipeStateIsUnloading[self.currentPipeState] then
					if ASEGlobals.devFeatures > 0 then print("not pipeStateIsUnloading") end
					allowedToDrive = false
				end
				if      not ( self.isPipeUnloading )
						and self.lastValidFillType   ~= FruitUtil.FRUITTYPE_UNKNOWN
						and ( ( self.lastArea        ~= nil and self.lastArea        > 0 )		
							 or ( self.lastCuttersArea ~= nil and self.lastCuttersArea > 0 ) ) then	
					if ASEGlobals.devFeatures > 0 then print("not waitingForTrailerToUnload") end
					tool.waitingForTrailerToUnload = true
				end
			elseif curCapa >= maxCapa then
				if ASEGlobals.devFeatures > 0 then print("not curCapa >= maxCapa") end
				allowedToDrive = false
			else 
				tool.waitingForTrailerToUnload = false
			end
			if tool.waitingForTrailerToUnload then
				do
					local trailer = self:findTrailerToUnload(self.lastValidFillType)
					if trailer ~= nil then
						tool.waitingForTrailerToUnload = false
					end
				end
			end
			if ( curCapa >= maxCapa and maxCapa > 0 ) or tool.waitingForTrailerToUnload or tool.waitingForDischarge then
				if ASEGlobals.devFeatures > 0 then print("not allowedToDrive "..tostring(curCapa).." >= "..tostring(maxCapa).." "..tostring(self.waitingForTrailerToUnload).." "..tostring(self.waitingForDischarge)) end
				allowedToDrive = false
			end

			if not self:getIsThreshingAllowed(true) then
				if ASEGlobals.devFeatures > 0 then print("not getIsThreshingAllowed") end
				allowedToDrive = false
				tool.waitingForWeather = true
			elseif tool.waitingForWeather then
				tool.waitingForWeather = false
			end
			
		elseif  checkFillLevel
				and self.capacity  ~= nil
				and self.capacity  > 0 
				and self.fillLevel ~= nil
				and self.fillLevel <= 0 then
			if ASEGlobals.devFeatures > 0 then print("emtpy") end
			allowedToDrive = false
    end
	end
		
	if not allowedToDrive then
		vehicle.lastNotAllowedToDrive = true
	elseif vehicle.lastNotAllowedToDrive then
		vehicle.lastNotAllowedToDrive = false
		AutoSteeringEngine.setToolsAreLowered( vehicle, true, false )		
	end
	
	return allowedToDrive
end

------------------------------------------------------------------------
-- checkIsAnimPlaying
------------------------------------------------------------------------
function AutoSteeringEngine.checkIsAnimPlaying( vehicle, moveDown )
	
	local isPlaying = false

	if vehicle.aseTools == nil or table.getn(vehicle.aseTools) < 1 then
		if ASEGlobals.devFeatures > 0 then print("no tools") end
		return false, false
	end
	
	for _,tool in pairs(vehicle.aseTools) do
		--if moveDown and tool.obj.startActivationTime ~= nil and tool.obj.startActivationTime <= g_currentMission.time then
		--	return true
		--end
		if tool.isPlough and tool.obj.rotationPart ~= nil then
			local self = tool.obj
			if self.rotationPart.turnAnimation ~= nil and self.getIsAnimationPlaying ~= nil then
        --local turnAnimTime = self:getAnimationTime(self.rotationPart.turnAnimation)
        --if turnAnimTime < self.rotationPart.touchAnimMaxLimit and turnAnimTime > self.rotationPart.touchAnimMinLimit then
				if self:getIsAnimationPlaying(self.rotationPart.turnAnimation) then
          return true, true
        end
			end
			if  self.rotationPart.node ~= nil then
				local x, y, z = getRotation(self.rotationPart.node)
				local maxRot = self.rotationPart.maxRot
				local minRot = self.rotationPart.minRot
				local eps = self.rotationPart.touchRotLimit
				if eps < math.abs(x - maxRot[1]) and eps < math.abs(x - minRot[1]) or eps < math.abs(y - maxRot[2]) and eps < math.abs(y - minRot[2]) or eps < math.abs(z - maxRot[3]) and eps < math.abs(z - minRot[3]) then
					return true, true
				end
			end
      if self.foldAnimTime ~= nil and (self.foldAnimTime > self.rotationPart.foldMaxLimit or self.foldAnimTime < self.rotationPart.foldMinLimit) then
				return true, true
      end
 		end
		
		if moveDown and tool.lowerStateOnFruits == nil then		
			if      tool.isTurnOnVehicle
					and tool.obj:getCanBeTurnedOn( )
					and not tool.obj:getIsTurnedOn( ) then
				tool.obj:setIsTurnedOn( true )
			end
			
			local isReady, noSneak = AutoSteeringEngine.checkToolIsReady( tool ) 
			
			if isReady == false and noSneak then
				if ASEGlobals.devFeatures > 0 then print("tool is not yet ready I") end
				if tool.ignoreAI then
					isPlaying = true
				else
					return true, true
				end
			elseif  isReady                   == nil 
					and tool.acWaitUntilIsLowered ~= nil 
					and tool.acWaitUntilIsLowered > g_currentMission.time then
				if ASEGlobals.devFeatures > 0 then print("tool is not yet ready II") end
				isPlaying = true
			end
		end
		--if moveDown and tool.isFoldable then
		--	local self = tool.obj
		--	if     self.foldMiddleDirection > 0.1 then
		--		if self.foldAnimTime > 1E-3 then
		--			return true
		--		end
		--	elseif self.foldMiddleDirection < -0.1 then
		--		if self.foldAnimTime < 0.999 then
		--			return true
		--		end
		--	end
		--end
	end
	
	return isPlaying, false
end

------------------------------------------------------------------------
-- checkToolIsReady
------------------------------------------------------------------------
function AutoSteeringEngine.checkToolIsReady( tool )
	local result   = nil
	local noSneak  = false
	
	if      tool.isTurnOnVehicle
			and tool.obj:getCanBeTurnedOn( )
			and not tool.obj:getIsTurnedOn( ) then
		return false, true
	end
	
	if      tool.obj.getDoGroundManipulation ~= nil
			and tool.obj:getDoGroundManipulation( ) then
		return true
	end

	if      tool.isPlough       
			and tool.obj.ploughHasGroundContact then
		return true
	elseif  tool.isCultivator   
			and tool.obj.cultivatorHasGroundContact then
		return true
	elseif  tool.isSowingMachine 
			and tool.obj.sowingMachineHasGroundContact then
		return true
	elseif  tool.isSprayer      
			and tool.obj:getIsReadyToSpray( ) then
		return true
	end
	
--if     tool.obj.movingDirection <= 0 
--		or tool.obj.lastSpeed       <= 8.3334e-4 then 
--	-- not moving => is ready to find some work to do...
--	return true, true
--end
	
	if     tool.isPlough        then
		result  = tool.obj.ploughHasGroundContact
		noSneak = true
	elseif tool.isCultivator    then
		result  = tool.obj.cultivatorHasGroundContact
		noSneak = true
	elseif tool.isSowingMachine then
		result  = tool.obj.sowingMachineHasGroundContact
		noSneak = true
	elseif tool.isSprayer       then
		result  = tool.obj:getIsReadyToSpray( )
		noSneak = true
	elseif tool.hasWorkAreas and tool.obj.groundReferenceNodes ~= nil then
		result = nil
		for _,n in pairs(tool.obj.groundReferenceNodes) do
			if n.isActive then
				local x, y, z = getWorldTranslation(n.node)
				local terrainHeight = getTerrainHeightAtWorldPos(g_currentMission.terrainRootNode, x, 0, z)
				y = y - terrainHeight
				if y > n.threshold then			
					result  = false
					noSneak = true
				elseif result == nil then
					result = true
				end
			end
		end
		if result == nil then
			result = false
		end
	end

	if result then return true end
	
	if tool.isCombine and tool.obj.isThreshing ~= nil then
		result = tool.obj.isThreshing
	end

	if     result then 
		return true
	elseif result == nil then
		return nil, false
	end
	return result, noSneak
end

------------------------------------------------------------------------
-- normalizeAngle
------------------------------------------------------------------------
function AutoSteeringEngine.normalizeAngle( b )
	local a = b
	while a >  math.pi do a = a - math.pi - math.pi end
	while a < -math.pi do a = a + math.pi + math.pi end
	return a
end

------------------------------------------------------------------------
-- getMaxSteeringAngle75
------------------------------------------------------------------------
function AutoSteeringEngine.getMaxSteeringAngle75( vehicle, invert )

	if vehicle.aseDirectionBeforeTurn == nil then
		vehicle.aseDirectionBeforeTurn = {}
	end
	
	if     vehicle.aseDirectionBeforeTurn.turn75 == nil then
		vehicle.aseDirectionBeforeTurn.turn75 = {}
		
		local index   = AutoSteeringEngine.getNoReverseIndex( vehicle )
		local radius  = vehicle.aseChain.radius
		local radiusT = vehicle.aseChain.radius
		local alpha   = vehicle.aseChain.maxSteering
		local radiusE = vehicle.aseChain.radius
		local diffE   = 0
		local gammaE  = 0
		
		if index > 0 then
			local tool    = vehicle.aseTools[index]
			local r       = vehicle.aseChain.radius
			local _,_,b1  = AutoSteeringEngine.getRelativeTranslation( vehicle.aseChain.refNode, tool.refNode )
			b1            = math.max( 0, -b1 )
			local b2
			if tool.b2 == nil then
				b2          = math.max( 0, -tool.zb )
			else
				b2          = math.max( 0, -tool.b2 )
			end
			local b3 = 0
			if tool.doubleJoint then
				b3 = tool.b3
			end
			if b1 < 0 and b2 < -1 then
				b2 = b2 + 0.5
				b1 = b1 - 0.5
			end

			if vehicle.articulatedAxis == nil then
				local diff   = math.huge
				local alpha1 = 0
				local alpha2 = ASEGlobals.maxToolAngle
				for f=0,1,0.01 do
					local a1 = f     * ASEGlobals.maxToolAngle
					local a2 = (1-f) * ASEGlobals.maxToolAngle
					local d  = math.abs( b1 * math.sin( a2 ) - b1 * math.sin( a1 ) )
					if diff > d then
						diff   = d
						alpha1 = a1
						alpha2 = a2
					end
				end
				
				local ra
				if b1 > b2 then
					ra = b1 / math.sin( alpha1 )
				else
					ra = b2 / math.sin( alpha2 )
				end
				
				radius = math.max( r, ra * math.cos( alpha1 ) )
				alpha  = math.min( vehicle.aseChain.maxSteering, math.atan( vehicle.aseChain.wheelBase / radius ) )
			end
			
			radiusT  = math.sqrt( math.max( radius*radius + b1*b1 - b2*b2 - b3*b3, 0 ) )
			radiusE  = r
			diffE    = 0.5 * math.max( 0, radiusE - radiusT )
			gammaE   = math.acos( math.min(math.max( 1 - diffE / radius, 0), 1 ) )
		end
						
		local diffT = vehicle.aseOtherX
		
		if invert then
			diffT = vehicle.aseActiveX
		else
			for i,tool in pairs(vehicle.aseTools) do
				if tool.isPlough or tool.specialType == "Packomat" then
					diffT = vehicle.aseActiveX
					break
				end
			end
		end		
		
		if diffT < 0 and ( vehicle.aseActiveX > 0 or vehicle.aseOtherX > 0 ) then -- vehicle.aseLRSwitch then
			diffT = -diffT
		end
		
		vehicle.aseDirectionBeforeTurn.turn75.index   = index 
		vehicle.aseDirectionBeforeTurn.turn75.radius  = radius
		vehicle.aseDirectionBeforeTurn.turn75.radiusT = radiusT
		vehicle.aseDirectionBeforeTurn.turn75.alpha   = alpha
		vehicle.aseDirectionBeforeTurn.turn75.diffE   = diffE  
		vehicle.aseDirectionBeforeTurn.turn75.gammaE  = gammaE
		vehicle.aseDirectionBeforeTurn.turn75.diffT   = diffT
	end
	
	return vehicle.aseDirectionBeforeTurn.turn75
end

------------------------------------------------------------------------
-- navigateToSavePoint
------------------------------------------------------------------------
function AutoSteeringEngine.navigateToSavePoint( vehicle, turnMode, fallback, Turn75 )

	if turnMode == nil or turnMode <= 0 then
		vehicle.aseDirectionBeforeTurn.targetTrace = nil
		return 0, false
	end

  -------------------------------------------------------
	local debugOutput = false 
	debugOutput = debugOutput and ( ASEGlobals.devFeatures > 0 )
  -------------------------------------------------------  

	if     vehicle.aseChain               == nil
			or vehicle.aseChain.maxSteering   == nil 
			or vehicle.aseDirectionBeforeTurn == nil then
		return 0, false
	end
	
	local uTurn = true
	if turnMode == 2 or turnMode == 4 then
		uTurn = false
	end

	local tvx, tvz = AutoSteeringEngine.getTurnVector( vehicle, uTurn )
	local wx,wy,wz = AutoSteeringEngine.getAiWorldPosition( vehicle )
	local angle    = nil
	local d1       = nil
	local onTrack  = true
	local radius   = Utils.getNoNil( vehicle.aseChain.radius, 5 ) * 1.1
--radius = radius + math.max( 0.1 * radius, 0.5 )
	
	local turn75 
	if     vehicle.aseDirectionBeforeTurn.targetTrace     == nil
			or vehicle.aseDirectionBeforeTurn.targetTraceMode ~= turnMode then
		--or math.abs( vehicle.aseActiveX - vehicle.aseDirectionBeforeTurn.aseActiveX ) > 0.2 then
		
		vehicle.aseDirectionBeforeTurn.targetTrace       = {}			
		vehicle.aseDirectionBeforeTurn.targetTraceMode   = turnMode	
		
		local shiftT = 0
		local rV     = radius
		local rT     = rV
		local mta    = 0.5 * math.pi - ASEGlobals.maxToolAngle

		if      type( Turn75 ) == "table"
				and Turn75.radius  ~= nil 
				and Turn75.radiusT ~= nil then 
			turn75 = Turn75
		else
			turn75 = AutoSteeringEngine.getMaxSteeringAngle75( vehicle )
		end
	
		if      mta            > 0
				and turn75.radius  > turn75.radiusT then				
			rT     = turn75.radius
			shiftT = turn75.radius - turn75.radiusT
		end
		
		if turnMode >= 3 then
			vehicle.aseDirectionBeforeTurn.targetTraceMinZ = math.min( 0, vehicle.aseDistance ) - 30
		else
			vehicle.aseDirectionBeforeTurn.targetTraceMinZ = math.min( 0, vehicle.aseDistance ) - 15
		end
		
	--print(tostring(vehicle.aseChain.radius).." "..tostring(rV).." "..tostring(rT).." "..tostring(turn75.radius).." "..tostring(turn75.radiusT))
		
		local p = {}
		if turnMode == 1 or turnMode == 3 then
			local ta      = AutoSteeringEngine.normalizeAngle( math.pi - AutoSteeringEngine.getTurnAngle( vehicle )	)
			local dx,_,dz = localDirectionToWorld( vehicle.aseChain.headlandNode, 0, 0, -1 )
					
			local zz  = 0

			if turnMode == 1 then
				if math.abs( tvx ) > 1 then
					zz = tvz - 0.5 * ( rV + rT )
				else
					zz = tvz
				end
				
				if     tvx >  1 then
					if not vehicle.aseLRSwitch then
						shiftT = shiftT - 0.5
					end
				elseif tvx < -1 then
					if vehicle.aseLRSwitch then
						shiftT = shiftT - 0.5
					end
				else
					shiftT = 0
				end
			end
			
			if shiftT <= 0 then
				shiftT = 0
				mta    = 0
			end
			
			local shiftZ = zz
			local toa = 0
			if shiftT > 0 and rT > 0 then
				toa = -math.asin( Utils.clamp( 1 - shiftT / rT, 0, 0.5 ) )
				zz  = zz + rT * math.sin( toa )
				if ASEGlobals.devFeatures > 0 then
					print("***********************************************************")
					print(string.format("%1.3fm %1.3fm => %3d° %1.3fm", shiftT, rT, math.deg( toa ), zz ))
				end
			end			
			
			local zl = zz + 1		
			while zl > vehicle.aseDirectionBeforeTurn.targetTraceMinZ do
				zl = zl - 1						
				local x,_,z = localDirectionToWorld( vehicle.aseChain.headlandNode, 0, 0, zl )
				x = vehicle.aseDirectionBeforeTurn.ux + x
				z = vehicle.aseDirectionBeforeTurn.uz + z
				table.insert( vehicle.aseDirectionBeforeTurn.targetTrace, 1, { x=x, z=z, dx=dx, dz=dz, a=0, ir=0 } )
			end			
			
			vehicle.aseDirectionBeforeTurn.targetTraceIOfs = table.getn( vehicle.aseDirectionBeforeTurn.targetTrace )
			
			if turnMode == 1 and math.abs( tvx ) > 1 then
				for i=1,50 do
					local a = ( 0.5 * math.pi - toa ) * i * 0.02 + toa
					local s = math.sin( a )
					local c = math.cos( a )
					
					local ir, lx, lz					
					if a > mta and rT > rV then
						ir = 1 / rV
						lx = c * rV + math.cos( mta ) * ( rT - rV ) 
						lz = s * rV + math.sin( mta ) * ( rT - rV )
					else
						ir = 1 / rT
						lx = c * rT
						lz = s * rT 
					end
					
					lx = lx - rT + shiftT
					if tvx > 0 then
					-- negative because getTurnVector inverts the sign
						lx = -lx
					end
					lz = lz + shiftZ
										
					x,_,z = localDirectionToWorld( vehicle.aseChain.headlandNode, lx, 0, lz )
					x = x + vehicle.aseDirectionBeforeTurn.ux
					z = z + vehicle.aseDirectionBeforeTurn.uz

					local j = table.getn( vehicle.aseDirectionBeforeTurn.targetTrace )
					dx = vehicle.aseDirectionBeforeTurn.targetTrace[j].x - x
					dz = vehicle.aseDirectionBeforeTurn.targetTrace[j].z - z
					if dx*dx+dz*dz > 0.04 then
						table.insert( vehicle.aseDirectionBeforeTurn.targetTrace, { x=x, z=z, dx=dx, dz=dz, a=a, ir=ir } )
					end
				end			
			elseif  turnMode       >  1
					and tvz            >= 1 
					and math.abs(tvx)  >= 0.1
					and math.abs( ta ) <= 0.75 * math.pi 
					and ( math.abs( ta ) > 1E-3 or math.abs( tvx ) < 0.1 ) 
					and ( ( ta >= 0 and tvx <= 0 ) or ( ta <= 0 and tvx >= 0 ) ) then
				local r  = radius
				local c  = math.cos( ta ) 
				local s  = math.sin( ta )
				local zo = 0
				local xo = 0
				
				if tvz * ( 1 - c) < math.abs( tvx * s ) then
					r  = tvz / math.abs( s )
					if tvx < 0 then r = -r end
				--xo = xo + tvx - r * ( 1 - c )
				else
					r  = tvx / ( 1 - c )
					zo = tvz - math.abs( r * s )
				end
				
				local iMax = math.max( 2, math.floor( math.abs( ta * r ) + 0.5 ) )
				
				for i=1,iMax do
					local a = ta * i / iMax
			
					x,_,z = localDirectionToWorld( vehicle.aseChain.headlandNode, xo + r * (1-math.cos( a )), 0, zo + math.abs( r * math.sin( a ) ) )
					x = x + vehicle.aseDirectionBeforeTurn.ux
					z = z + vehicle.aseDirectionBeforeTurn.uz
				
					local j = table.getn( vehicle.aseDirectionBeforeTurn.targetTrace )
					dx = vehicle.aseDirectionBeforeTurn.targetTrace[j].x - x
					dz = vehicle.aseDirectionBeforeTurn.targetTrace[j].z - z
					if dx*dx+dz*dz > 0.04 then
						table.insert( vehicle.aseDirectionBeforeTurn.targetTrace, { x=x, z=z, dx=dx, dz=dz, a=a, ir=1/r } )
					end
				end		
			end
			
		elseif turnMode == 5 then
			-- continue in previous direction 
			local dx,_,dz = localDirectionToWorld( vehicle.aseChain.headlandNode, 0, 0, 1 )
			local zl = 1		
			while zl > vehicle.aseDirectionBeforeTurn.targetTraceMinZ do
				zl = zl - 1						
				local x,_,z = localDirectionToWorld( vehicle.aseChain.headlandNode, 0, 0, -zl )
				x = vehicle.aseDirectionBeforeTurn.ux + x
				z = vehicle.aseDirectionBeforeTurn.uz + z
				table.insert( vehicle.aseDirectionBeforeTurn.targetTrace, 1, { x=x, z=z, dx=dx, dz=dz, a=0, ir=0 } )
			end			
			
			vehicle.aseDirectionBeforeTurn.targetTraceIOfs = table.getn( vehicle.aseDirectionBeforeTurn.targetTrace )
		
		elseif turnMode == 2 or turnMode == 4 then
			-- negative Z is beyond turn point in old direction
			-- negative X is beyond turn point in new direction 
			
			local dx, dz
			if vehicle.aseLRSwitch then
				dx,_,dz = localDirectionToWorld( vehicle.aseChain.headlandNode, -1, 0, 0 )				
			else
				dx,_,dz = localDirectionToWorld( vehicle.aseChain.headlandNode,  1, 0, 0 )				
			end			
			
			local shiftX = tvx
			if not vehicle.aseLRSwitch then
				shiftX = -shiftX 
			end
			
			if shiftT <= 0 then
				shiftT = 0
				mta    = 0
			end
				
			if turnMode == 2 then
				if mta > 0 then
					shiftX = shiftX - rV - math.sin( mta ) * ( rT - rV )
				else
					shiftX = shiftX - rV 
				end
			end
			
			local zz  = shiftX - 2
			local toa = 0
			if shiftT > 0 and rT > 0 then
				toa = -math.asin( Utils.clamp( 1 - shiftT / rT, 0, 0.5 ) )
				zz  = zz + rT * math.sin( toa )
				if ASEGlobals.devFeatures > 0 then
					print("***********************************************************")
					print(string.format("%1.3fm %1.3fm => %3d° %1.3fm", shiftT, rT, math.deg( toa ), zz ))
				end
			end
			
			local zl = zz + 1						
			while zl > vehicle.aseDirectionBeforeTurn.targetTraceMinZ do
				zl = zl - 1
				
				local zd = math.min( 0, zl - zz )
				local zf = zl - zd
				local lx = zd + zf
				
				if not vehicle.aseLRSwitch then
					lx = -lx
				end
				
				x,_,z = localDirectionToWorld( vehicle.aseChain.headlandNode, lx, 0, 0 )				
				x = x + vehicle.aseDirectionBeforeTurn.cx 
				z = z + vehicle.aseDirectionBeforeTurn.cz 
				table.insert( vehicle.aseDirectionBeforeTurn.targetTrace, 1, { x=x, z=z, dx=dx, dz=dz, a=0, ir=0 } )
			end			
			
			vehicle.aseDirectionBeforeTurn.targetTraceIOfs = table.getn( vehicle.aseDirectionBeforeTurn.targetTrace )
			
			if turnMode == 2 then
				for i=1,50 do
					local a = ( 0.5 * math.pi - toa ) * i * 0.02 + toa
					local s = math.sin( a )
					local c = math.cos( a )
					
					local ir, lx, lz
					if a > mta and rT > rV then
						ir = 1 / rV
						lx = shiftX + s * rV + math.sin( mta ) * ( rT - rV )
						lz = shiftT + c * rV + math.cos( mta ) * ( rT - rV ) 
					else
						ir = 1 / rT
						lx = shiftX + s * rT
						lz = shiftT + c * rT
					end
					
					lz = lz - rT
					if not vehicle.aseLRSwitch then
						lx = -lx
					end
					
					if tvz > 1 then
						lz = -lz
					end
					
					x,_,z = localDirectionToWorld( vehicle.aseChain.headlandNode, lx, 0, lz )
					x = x + vehicle.aseDirectionBeforeTurn.cx
					z = z + vehicle.aseDirectionBeforeTurn.cz

					local j = table.getn( vehicle.aseDirectionBeforeTurn.targetTrace )
					dx = vehicle.aseDirectionBeforeTurn.targetTrace[j].x - x
					dz = vehicle.aseDirectionBeforeTurn.targetTrace[j].z - z
					if dx*dx+dz*dz > 0.04 then
						table.insert( vehicle.aseDirectionBeforeTurn.targetTrace, { x=x, z=z, dx=dx, dz=dz, a=a, ir=ir } )
					end
				end			
			end
		else
			print("ERROR in AutoSterringEngine.navigateToSavePoint: invalid turn mode: "..tostring(turnMode))
		end

		if table.getn( vehicle.aseDirectionBeforeTurn.targetTrace ) > vehicle.aseDirectionBeforeTurn.targetTraceIOfs then
			local p = vehicle.aseDirectionBeforeTurn.targetTrace[vehicle.aseDirectionBeforeTurn.targetTraceIOfs]
			local q = vehicle.aseDirectionBeforeTurn.targetTrace[vehicle.aseDirectionBeforeTurn.targetTraceIOfs+1]
			local d = math.floor( math.sqrt( (p.x-q.x)^2 + (p.z-q.z)^2 ) ) - 1
			
			for i=1,d do
				x  = p.x + i/(d+1)*(q.x-p.x)
				z  = p.z + i/(d+1)*(q.z-p.z)
				dx = q.x - p.x
				dz = q.z - p.z
				local j = vehicle.aseDirectionBeforeTurn.targetTraceIOfs + i
				table.insert( vehicle.aseDirectionBeforeTurn.targetTrace, j, { x=x, z=z, dx=dx, dz=dz, a=0, ir=0 } )
			end			
		end
		
		vehicle.aseDirectionBeforeTurn.targetTraceMinZ = nil
		if ASEGlobals.devFeatures > 0 then
			print("***********************************************************")
			for i,p in pairs( vehicle.aseDirectionBeforeTurn.targetTrace ) do
				local lx,_,lz = worldToLocal( vehicle.aseChain.refNode, p.x, wy, p.z )
				local kx,_,kz = worldDirectionToLocal( vehicle.aseChain.refNode, p.dx, 0, p.dz )
				if p.a == nil then
					print(string.format("nil° %1.3fm %1.3fm / %1.3fm %1.3fm",lx,lz,kx,kz ))
				else
					print(string.format("%3d° %1.3fm %1.3fm / %1.3fm %1.3fm",math.deg(p.a),lx,lz,kx,kz ))
				end
			end
			print("***********************************************************")
		end	
	end
	
	if      vehicle.aseDirectionBeforeTurn.targetTrace       ~= nil 
			and vehicle.aseDirectionBeforeTurn.targetTraceMode   >  0
			and ( vehicle.aseDirectionBeforeTurn.targetTraceMinZ == nil
			   or tvz > vehicle.aseDirectionBeforeTurn.targetTraceMinZ ) then				

		if AutoSteeringEngine.quot2Rad == nil then
			AutoSteeringEngine.quot2Rad = AnimCurve:new(linearInterpolator1)
			
      AutoSteeringEngine.quot2Rad:addKeyframe( { time=-22.9037655484312, v=-3.05432619099008 })
      AutoSteeringEngine.quot2Rad:addKeyframe( { time=-7.59575411272514, v=-2.87979326579064 })
      AutoSteeringEngine.quot2Rad:addKeyframe( { time=-4.51070850366206, v=-2.70526034059121 })
      AutoSteeringEngine.quot2Rad:addKeyframe( { time=-3.17159480236321, v=-2.53072741539178 })
      AutoSteeringEngine.quot2Rad:addKeyframe( { time=-2.41421356237309, v=-2.35619449019234 })
      AutoSteeringEngine.quot2Rad:addKeyframe( { time=-1.92098212697117, v=-2.18166156499291 })
      AutoSteeringEngine.quot2Rad:addKeyframe( { time=-1.56968557711749, v=-2.00712863979348 })
      AutoSteeringEngine.quot2Rad:addKeyframe( { time=-1.30322537284121, v=-1.83259571459405 })
      AutoSteeringEngine.quot2Rad:addKeyframe( { time=-1.09130850106927, v=-1.65806278939461 })
      AutoSteeringEngine.quot2Rad:addKeyframe( { time=-0.916331174017423, v=-1.48352986419518 })
      AutoSteeringEngine.quot2Rad:addKeyframe( { time=-0.76732698797896, v=-1.30899693899575 })
      AutoSteeringEngine.quot2Rad:addKeyframe( { time=-0.637070260807493, v=-1.13446401379631 })
      AutoSteeringEngine.quot2Rad:addKeyframe( { time=-0.520567050551746, v=-0.959931088596881 })
      AutoSteeringEngine.quot2Rad:addKeyframe( { time=-0.414213562373095, v=-0.785398163397448 })
      AutoSteeringEngine.quot2Rad:addKeyframe( { time=-0.315298788878984, v=-0.610865238198015 })
      AutoSteeringEngine.quot2Rad:addKeyframe( { time=-0.22169466264294, v=-0.436332312998582 })
      AutoSteeringEngine.quot2Rad:addKeyframe( { time=-0.131652497587396, v=-0.261799387799149 })
      AutoSteeringEngine.quot2Rad:addKeyframe( { time=-0.0436609429085119, v=-0.0872664625997165 })
      AutoSteeringEngine.quot2Rad:addKeyframe( { time=0.0436609429085119, v=0.0872664625997165 })
      AutoSteeringEngine.quot2Rad:addKeyframe( { time=0.131652497587396, v=0.261799387799149 })
      AutoSteeringEngine.quot2Rad:addKeyframe( { time=0.22169466264294, v=0.436332312998582 })
      AutoSteeringEngine.quot2Rad:addKeyframe( { time=0.315298788878984, v=0.610865238198015 })
      AutoSteeringEngine.quot2Rad:addKeyframe( { time=0.414213562373095, v=0.785398163397448 })
      AutoSteeringEngine.quot2Rad:addKeyframe( { time=0.520567050551746, v=0.959931088596881 })
      AutoSteeringEngine.quot2Rad:addKeyframe( { time=0.637070260807493, v=1.13446401379631 })
      AutoSteeringEngine.quot2Rad:addKeyframe( { time=0.76732698797896, v=1.30899693899575 })
      AutoSteeringEngine.quot2Rad:addKeyframe( { time=0.916331174017423, v=1.48352986419518 })
      AutoSteeringEngine.quot2Rad:addKeyframe( { time=1.09130850106927, v=1.65806278939461 })
      AutoSteeringEngine.quot2Rad:addKeyframe( { time=1.30322537284121, v=1.83259571459405 })
      AutoSteeringEngine.quot2Rad:addKeyframe( { time=1.56968557711749, v=2.00712863979348 })
      AutoSteeringEngine.quot2Rad:addKeyframe( { time=1.92098212697117, v=2.18166156499291 })
      AutoSteeringEngine.quot2Rad:addKeyframe( { time=2.41421356237309, v=2.35619449019234 })
      AutoSteeringEngine.quot2Rad:addKeyframe( { time=3.17159480236321, v=2.53072741539178 })
      AutoSteeringEngine.quot2Rad:addKeyframe( { time=4.51070850366206, v=2.70526034059121 })
      AutoSteeringEngine.quot2Rad:addKeyframe( { time=7.59575411272514, v=2.87979326579064 })
      AutoSteeringEngine.quot2Rad:addKeyframe( { time=22.9037655484312, v=3.05432619099008 })
		end
		
		if debugOutput then
			print("=========================================================")
			local x,_,z = getWorldTranslation( vehicle.aseChain.refNode )
			print(tostring(x).." "..tostring(z).." / "..tostring(wx).." "..tostring(wz))
		end
		
		local score = {}
		for i=1,5 do
			score[i] = { score = math.huge }
		end
		
		for i,p in pairs(vehicle.aseDirectionBeforeTurn.targetTrace) do
		--local x,_,z   = worldToLocal( vehicle.aseChain.refNode, p.x, wy, p.z )
			local x,_,z   = worldDirectionToLocal( vehicle.aseChain.refNode, p.x-wx, 0, p.z-wz )
			local dx,_,dz = worldDirectionToLocal( vehicle.aseChain.refNode, p.dx, 0, p.dz )
			
		--if i > 1 then
		--	local q = vehicle.aseDirectionBeforeTurn.targetTrace[i-1]
		--  dx,_,dz = worldDirectionToLocal( vehicle.aseChain.refNode, q.x-p.x, 0, q.z-p.z )
		--end
			
			if z > 1 then					
				if debugOutput then
					print(tostring(x).." "..tostring(z).." / "..tostring(dx).." "..tostring(dz))
				end
				
				if math.abs( x ) <= 22.9 * math.abs( z ) then
					local alpha = AutoSteeringEngine.quot2Rad:get( x/z )					
					local beta  = math.atan2( dx, dz )
										
					if math.abs(x) < math.abs(z) then
						a = math.atan2( vehicle.aseChain.wheelBase * math.sin( alpha ), z )					
					else
						a = math.atan2( vehicle.aseChain.wheelBase * (1-math.cos( alpha )), math.abs(x) )					
						if x < 0 then
							a = -a
						end
					end
					
					a = a + 0.5 * ( alpha - beta )
					
					if math.abs( a ) <= 1.25 * vehicle.aseChain.maxSteering then
						local d = x*x+z*z 						
					--local s = 1000 * math.abs( p.ir - math.tan( a ) / vehicle.aseChain.wheelBase )
						local s = math.abs( 9 - d )
						local b = math.abs( alpha - beta ) 
						
						if debugOutput then
							print("=> "..tostring(math.deg(alpha)).."° "..tostring(math.deg(beta)).."° ===> "..tostring(math.deg(a)).."°")
						end
						
						for j=1,table.getn( score ) do
							if s <= score[j].score then
								for k=table.getn( score )-1, j,-1 do
									if score[k].angle ~= nil then
										score[k+1].score = score[k].score
										score[k+1].angle = score[k].angle
										score[k+1].dist  = score[k].dist 
										score[k+1].beta  = score[k].beta 
									end
								end
								score[j].score = s
								score[j].angle = a
								score[j].dist  = d
								score[j].beta  = b
								break
							end
						end
					end			
				end				
			end
		end
		
		n     = 0
		angle = nil
		bestD = nil
		bestB = nil
	--for k=1,2 do
		for k=2,2 do
			for j=1,table.getn( score ) do
				if score[j].angle == nil then
					break
				elseif k == 2 or score[j].score < 10 then
					if n > 0 then
						n     = n + 1
						angle = angle + score[j].angle
						bestD = bestD + score[j].dist 
						bestB = bestB + score[j].beta 
					else
						n     = 1
						angle = score[j].angle
						bestD = score[j].dist 
						bestB = score[j].beta 						
					--if k == 1 then break end
					end
				end
			end
			if n > 0 then
				break
			end
		end
		
		if n > 1 then
			angle = angle / n
			bestD = bestD / n
			bestB = bestB / n
		end
		
		if debugOutput then
			print("---------------------------------")
			for j=1,table.getn( score ) do
				if score[j].angle == nil then
					break
				else
					print(string.format("%2d: s: %2.3f a: %2.1f° d: %2.3fm b: %2.1f°", j, score[j].score, math.deg( score[j].angle ), math.sqrt( score[j].dist ), math.deg( score[j].beta ) ) )
				end
			end
		end
		
		if      angle ~= nil 
				and ASEGlobals.devFeatures > 0 then
			print(tostring(math.deg(angle)).."° "..tostring(n).." "..tostring(bestD).." "..tostring(bestB))
		end
	end
	
	if angle == nil then
		onTrack = false
		
		if vehicle.aseDirectionBeforeTurn.targetTraceMode == 1 then
			vehicle.aseDirectionBeforeTurn.targetTraceMode = 0
		end
		
		if fallback ~= nil then
			angle = fallback( vehicle, uTurn )
			if ASEGlobals.devFeatures > 0 then
				print("Fallback angle: "..math.floor( 0.5 + math.deg( angle )))
			end
		else
			angle = 0
			if ASEGlobals.devFeatures > 0 then
				print("No angle found")
			end
		end
	end
	
	angle = math.min( math.max( angle, -vehicle.aseChain.maxSteering  ), vehicle.aseChain.maxSteering  )
	
	return angle, onTrack
end

------------------------------------------------------------------------
-- setToolsAreTurnedOn
------------------------------------------------------------------------
function AutoSteeringEngine.setToolsAreTurnedOn( vehicle, isTurnedOn, immediate, objectFilter )
	if not ( vehicle.aseChain ~= nil and vehicle.aseLRSwitch ~= nil and vehicle.aseToolCount ~= nil and vehicle.aseToolCount >= 1 ) then
		return
	end
	
	AutoSteeringEngine.setToolsAreLowered( vehicle, isTurnedOn, immediate, objectFilter )
	
	for i=1,vehicle.aseToolCount do
		if objectFilter == nil or objectFilter == vehicle.aseTools[i].obj then
			local self = vehicle.aseTools[i].obj
			if     vehicle.aseTools[i].specialType == "Poettinger X8"          then
				local idx = self.x8.selectionIdx
				self:setSelection( 3 )
				if isTurnedOn then
					self:setTransport( false )
				end
				self:setTurnedOn( isTurnedOn )
				self:setSelection( idx )
			elseif vehicle.aseTools[i].specialType == "Poettinger AlphaMotion" then
				if isTurnedOn then
					self:setTransport( false )
				end
				self:setTurnedOn( isTurnedOn )
			elseif vehicle.aseTools[i].specialType == "Horsch SW3500 S"        then
			--if isTurnedOn and self.Go.trsp ~= isTurnedOn then
			--	self:setStateEvent("Speed", "trsp", 1.0)
			--	self:setStateEvent("Go", "trsp", isTurnedOn)
			--	self:setStateEvent("Done", "trsp", true)
			--end
				if self.turnOn ~= isTurnedOn then
					self:setStateEvent("turnOn", false, isTurnedOn)
				end
			elseif vehicle.aseTools[i].isCombine then
				if self.setIsTurnedOn ~= nil then
					self:setIsTurnedOn( isTurnedOn )
				end
				if isTurnedOn then
					self:startThreshing( true )
					self:aiLower( )
				else
					self:aiRaise( )
					self:stopThreshing( true )
				end
				self.waitingForDischarge       = false
				self.waitForDischargeTime      = 0
				self.waitingForTrailerToUnload = false
			elseif vehicle.aseTools[i].isAITool then
				if isTurnedOn then
					self:aiTurnOn()
				else
					self:aiTurnOff()
				end
			else
				if self.setIsTurnedOn ~= nil then
					self:setIsTurnedOn(isTurnedOn, true)
				end
				--if vehicle.aseTools[i].isFoldable and self:getIsFoldAllowed() then
				--	if isTurnedOn then
				--		if self.turnOnFoldDirection ~= 0 then
				--			self:setFoldDirection(self.turnOnFoldDirection)
				--		end
				--	else
				--		if self.foldMiddleAIRaiseDirection ~= 0 then
				--			self:setFoldState(-self.foldMiddleAIRaiseDirection, true)
				--		end
				--	end
				--end
				if self.setAIImplementsMoveDown ~= nil then
					self:setAIImplementsMoveDown( isTurnedOn )
				end
			end
		end
	end
end

------------------------------------------------------------------------
-- setToolIsLowered
------------------------------------------------------------------------
function AutoSteeringEngine.setToolIsLowered( tool, isLowered )
	local self = tool.obj
	if     tool.isCombine                               then
		if self.setIsTurnedOn ~= nil then
			self:setIsTurnedOn( isLowered )
		end
		if isLowered then
			self:aiLower( )
		else
			self:aiRaise( )
		end
		if isLowered and not self.isThreshing then
			self:startThreshing( true )
		end
	elseif tool.isSprayer                               then
		self:setIsTurnedOn( isLowered, true )
	elseif tool.specialType == "Poettinger X8"          then
		local idx = self.x8.selectionIdx
		self:setSelection( 3 )
		self:setLiftUp( not isLowered )
		self:setSelection( idx )
	elseif tool.specialType == "Poettinger AlphaMotion" then
		self:setLiftUp( not isLowered )
	elseif tool.specialType == "Taarup Mower"           then
		if self.setTransRot ~= nil then
			self:setTransRot( isLowered )
		end
		if      self.mowerFoldingParts ~= nil 
				and self.setIsArmDown      ~= nil then
			for k, part in pairs(self.mowerFoldingParts) do
				self:setIsArmDown( k, isLowered )
			end
		end
	elseif tool.specialType == "Horsch SW3500 S"        then
		if self.Go.down ~= isLowered then
			if isLowered then
				self:aiLower( )
			else
				self:aiRaise( )
			end
		end
	elseif self.setAIImplementsMoveDown ~= nil then
		self:setAIImplementsMoveDown( isLowered )
	elseif self.aiLower ~= nil and self.aiRaise ~= nil then 
		if isLowered then
			self:aiLower( )
		else
			self:aiRaise( )
		end
	--elseif tool.isFoldable then
	--	if self:getIsFoldAllowed() and self.foldMiddleAIRaiseDirection ~= 0 then
	--		if isLowered then
	--			self:setFoldState(-self.foldMiddleAIRaiseDirection, true )
	--		else
	--			self:setFoldState(self.foldMiddleAIRaiseDirection, true )
	--		end
	--	end
	end			
end

------------------------------------------------------------------------
-- setToolsAreLowered
------------------------------------------------------------------------
function AutoSteeringEngine.setToolsAreLowered( vehicle, isLowered, immediate, objectFilter )
	if not ( vehicle.aseChain ~= nil and vehicle.aseLRSwitch ~= nil and vehicle.aseToolCount ~= nil and vehicle.aseToolCount >= 1 ) then
		return
	end
	
	local doItNow = false
	for i=1,vehicle.aseToolCount do
		if      isLowered 
				and vehicle.aseTools[i].isCombine then
			doItNow = true
		end
		vehicle.aseTools[i].lowerStateOnFruits = isLowered
	end	
	if doItNow or immediate or objectFilter ~= nil then
		for i=1,table.getn( vehicle.aseToolParams ) do
			if     immediate
					or vehicle.aseTools[vehicle.aseToolParams[i].i].obj == objectFilter
					or ( isLowered
					 and vehicle.aseTools[vehicle.aseToolParams[i].i].isCombine 
					 and vehicle.aseTools[vehicle.aseToolParams[i].i].obj.lastValidInputFruitType == FruitUtil.FRUITTYPE_UNKNOWN ) then
				AutoSteeringEngine.ensureToolIsLowered( vehicle, isLowered, i )
			end
		end
	end
end

------------------------------------------------------------------------
-- raiseToolNoFruits
------------------------------------------------------------------------
function AutoSteeringEngine.raiseToolNoFruits( vehicle, objectFilter )
	if not ( vehicle.aseChain ~= nil and vehicle.aseLRSwitch ~= nil and vehicle.aseToolCount ~= nil and vehicle.aseToolCount >= 1 ) then
		return
	end
	
	for i=1,table.getn( vehicle.aseToolParams ) do
		if  not vehicle.aseTools[vehicle.aseToolParams[i].i].isCombine
				and vehicle.aseTools[vehicle.aseToolParams[i].i].obj == objectFilter then
			vehicle.aseTools[vehicle.aseToolParams[i].i].lowerStateOnFruits = false
			AutoSteeringEngine.ensureToolIsLowered( vehicle, false, i )
			vehicle.aseTools[vehicle.aseToolParams[i].i].lowerStateOnFruits = true
		end
	end
end

------------------------------------------------------------------------
-- setToolsAreLowered
------------------------------------------------------------------------
function AutoSteeringEngine.setPloughTransport( vehicle, isTransport, excludePackomat )
	if not ( vehicle.aseChain ~= nil and vehicle.aseLRSwitch ~= nil and vehicle.aseToolCount ~= nil and vehicle.aseToolCount >= 1 ) then
		return
	end
	for i=1,vehicle.aseToolCount do
		if      vehicle.aseTools[i].specialType == "Packomat"
				and ( excludePackomat == nil or not excludePackomat ) then
				
			local self = vehicle.aseTools[i].obj
			if self.transport ~= isTransport then
				self:setStateEvent("transport", isTransport )
			end
		elseif  vehicle.aseTools[i].ploughTransport
				and vehicle.aseTools[i].obj:getIsPloughRotationAllowed() then
			local self = vehicle.aseTools[i].obj
			local curAnimTime = self:getAnimationTime(self.rotationPart.turnAnimation)
			local tgtAnimTime = curAnimTime 
			if     isTransport then
				tgtAnimTime = 0.5
			elseif self.rotationMax then
				tgtAnimTime = 1
			else
				tgtAnimTime = -1
			end
			
			self:stopAnimation( self.rotationPart.turnAnimation )
			if curAnimTime ~= tgtAnimTime then
				if tgtAnimTime > curAnimTime then
					self:playAnimation( self.rotationPart.turnAnimation, 1, curAnimTime, true)
				else
					self:playAnimation( self.rotationPart.turnAnimation, -1, curAnimTime, true)
				end
				if 0 < tgtAnimTime and tgtAnimTime < 1 then
					self:setAnimationStopTime( self.rotationPart.turnAnimation, tgtAnimTime )
				end
			end
		end
	end	
end

------------------------------------------------------------------------
-- ensureToolsLowered
------------------------------------------------------------------------
function AutoSteeringEngine.ensureToolIsLowered( vehicle, isLowered, indexFilter )
	if not ( vehicle.aseChain ~= nil and vehicle.aseLRSwitch ~= nil and vehicle.aseToolCount ~= nil and vehicle.aseToolCount >= 1 ) then
		return
	end
	
	for i=1,table.getn( vehicle.aseToolParams ) do
		local doit = false
		if indexFilter == nil or indexFilter <= 0 then
			if vehicle.aseTools[vehicle.aseToolParams[i].i].lowerStateOnFruits ~= nil then
				doit = true
			end
		elseif i == indexFilter then
			if      vehicle.aseTools[vehicle.aseToolParams[i].i].lowerStateOnFruits ~= nil 
					and vehicle.aseTools[vehicle.aseToolParams[i].i].lowerStateOnFruits == isLowered then
				doit = true
			end
		end
		if doit then
		--if ASEGlobals.devFeatures > 0 then AutoTractor.printCallstack() end
		
			vehicle.aseTools[vehicle.aseToolParams[i].i].lowerStateOnFruits   = nil 
			vehicle.aseTools[vehicle.aseToolParams[i].i].acWaitUntilIsLowered = g_currentMission.time + vehicle.acDeltaTimeoutStart -- vehicle.acDeltaTimeoutRun
			for _,implement in pairs(vehicle.attachedImplements) do
				if      implement.object == vehicle.aseTools[vehicle.aseToolParams[i].i].obj
						and ( implement.object.needsLowering or implement.object.aiNeedsLowering )
						then
					vehicle.setJointMoveDown( vehicle, implement.jointDescIndex, isLowered, true )
				end
			end
			AutoSteeringEngine.setToolIsLowered( vehicle.aseTools[vehicle.aseToolParams[i].i], isLowered )
		end
	end
	
	if indexFilter == nil or indexFilter <= 0 then
		for _,implement in pairs(vehicle.attachedImplements) do
			if implement.object ~= nil then
				local found = false
				for i=1,table.getn( vehicle.aseToolParams ) do
					if implement.object == vehicle.aseTools[vehicle.aseToolParams[i].i].obj then	
						found = true
						break
					end
				end
				if      not found
						and ( implement.object.needsLowering or implement.object.aiNeedsLowering )
						then
					vehicle.setJointMoveDown( vehicle, implement.jointDescIndex, isLowered, true )
				end
			end
		end
	end
end

------------------------------------------------------------------------
-- ensureToolsLowered
------------------------------------------------------------------------
function AutoSteeringEngine.findComponentJointDistance( vehicle, tool, object )
	
	if     object.attacherJoint              ~= nil
			and object.attacherJoint.jointType    ~= nil
			and ( object.attacherJoint.jointType  == Vehicle.JOINTTYPE_TRAILERLOW
			   or object.attacherJoint.jointType  == Vehicle.JOINTTYPE_TRAILER ) then
		return 0
	end
	
	return -0.7
end

------------------------------------------------------------------------
-- greenDirectCut
------------------------------------------------------------------------
function AutoSteeringEngine.greenDirectCut( vehicle, resetShift )
	if     not ( vehicle.aseChain ~= nil and vehicle.aseLRSwitch ~= nil and vehicle.aseToolCount ~= nil and vehicle.aseToolCount >= 1 )
			or ZZZ_greenDirectCut                                    == nil 
			or ZZZ_greenDirectCut.greenDirectCut                     == nil
			or ZZZ_greenDirectCut.greenDirectCut.shiftMinGrowthState == nil
			or ZZZ_greenDirectCut.greenDirectCut.forceGreenForage    == nil then
		return
	end
	
	local shiftDone  = false
	local shiftValue = -1
	
	if resetShift then
		shiftValue = 1
	end
	
	for i=1,vehicle.aseToolCount do
		local object = vehicle.aseTools[i].obj
		if object ~= nil and object.convertedFruits ~= nil then
			shiftDone = true
			ZZZ_greenDirectCut.greenDirectCut:shiftMinGrowthState(object,shiftValue)
			if g_currentMission.missionStats.difficulty == 3 then
				ZZZ_greenDirectCut.greenDirectCut:forceGreenForage(object,resetShift)
			end
		end
	end
	
	return shiftDone
end

--***************************************************************
-- getRelativeZTranslation
--***************************************************************
function AutoSteeringEngine.getRelativeZTranslation(root,node)
	local x,y,z = AutoSteeringEngine.getRelativeTranslation(root,node)
	return z
end

--***************************************************************
-- getWorldYRotation
--***************************************************************
function AutoSteeringEngine.getWorldYRotation(node)
	local x, _, z = localDirectionToWorld(node, 0, 0, 1)
	if math.abs(x) < 1e-3 and math.abs(z) < 1e-3 then
		return 0
	end
	return AutoSteeringEngine.normalizeAngle( math.atan2(z,x) + 1.5707963268 )
end

--***************************************************************
-- tableGetN
--***************************************************************
function AutoSteeringEngine.tableGetN( tab )
	if type( tab ) == "table" then
		return table.getn( tab )
	end
	return 0
end	

--***************************************************************
-- getTaJoints1
--***************************************************************
function AutoSteeringEngine.getTaJoints1( vehicle, refNode, zOffset )
	
	if     AutoSteeringEngine.tableGetN( vehicle.attacherJoints )     < 1
			or AutoSteeringEngine.tableGetN( vehicle.attachedImplements ) < 1 then
		return
	end
	
	local taJoints
	
	for _,implement in pairs( vehicle.attachedImplements ) do
		if      implement.object ~= nil 
				and implement.object.steeringAxleNode ~= nil 
				and ( AutoSteeringEngine.tableGetN( implement.object.wheels ) > 0
					 or AutoSteeringEngine.tableGetN( implement.object.attachedImplements ) > 0 ) 
				and AutoSteeringEngine.getRelativeZTranslation( refNode, implement.object.steeringAxleNode ) < zOffset then

			local taJoints2 = AutoSteeringEngine.getTaJoints2( vehicle, implement, refNode, zOffset )
			local iLast     = AutoSteeringEngine.tableGetN( taJoints2 )
			if iLast > 0 then
				if taJoints == nil then
					taJoints = {}
				end
				for i,joint in pairs( taJoints2 ) do
					table.insert( taJoints, joint )
				end
				break
			end
		end
	end
	
	return taJoints 
end

--***************************************************************
-- getComponentOfNode
--***************************************************************
function AutoSteeringEngine.getComponentOfNode( vehicle, node )

	if node == nil then
		return 0
  end
	
	for i,c in pairs(vehicle.components) do
		if c.node == node then
			return i
		end
	end
	
	local state, result = pcall( getParent, node )
	
	if state and result ~= nil then
		return AutoSteeringEngine.getComponentOfNode( vehicle, getParent( node ) )
	else
		return 0
	end
end
	
--***************************************************************
-- getTaJoints2
--***************************************************************
function AutoSteeringEngine.getTaJoints2( vehicle, implement, refNode, zOffset )

	if     type( implement )       ~= "table"
			or type( implement.object) ~= "table"
			or refNode                 == nil
			or AutoSteeringEngine.tableGetN( vehicle.attacherJoints ) < 1
			or implement.object.steeringAxleNode == nil then
		return 
	end
		
	local taJoints
	local trailer  = implement.object

	if      AutoSteeringEngine.tableGetN( trailer.attacherJoints )     > 0
			and AutoSteeringEngine.tableGetN( trailer.attachedImplements ) > 0 then
		taJoints = AutoSteeringEngine.getTaJoints1( trailer, trailer.steeringAxleNode, 0 )
	end
	
	if taJoints == nil then 
		taJoints = {}
	end
	
  local index = AutoSteeringEngine.tableGetN( taJoints ) + 1
	

	if      implement.jointRotLimit    ~= nil
			and implement.jointRotLimit[2] ~= nil
			and implement.jointRotLimit[2] >  math.rad( 0.1 ) then
		table.insert( taJoints, index,
									{ nodeVehicle  = vehicle.attacherJoints[implement.jointDescIndex].rootNode, --refNode, 
										nodeTrailer  = trailer.attacherJoint.rootNode, 
										targetFactor = 1 } )
	end
	
	if      AutoSteeringEngine.tableGetN( trailer.wheels )          > 0
			and AutoSteeringEngine.tableGetN( trailer.components )      > 1
			and AutoSteeringEngine.tableGetN( trailer.componentJoints ) > 0 then
		
		local na = AutoSteeringEngine.getComponentOfNode( trailer, trailer.attacherJoint.rootNode )
		
		if na > 0 then		
			local wcn = {}
			
			for _,wheel in pairs( trailer.wheels ) do
				local n = AutoSteeringEngine.getComponentOfNode( trailer, wheel.node )
				if n > 0 then
					wcn[n] = true
				end
			end			
			
			local nextN = { na }
			local allN  = {}
			
			while AutoSteeringEngine.tableGetN( nextN ) > 0 do				
				local thisN = {}
				for _,n in pairs( nextN ) do
					if not ( allN[n] ) then
						thisN[n] = true
						allN[n]  = true
					end
				end
				nextN = {}
				
				for _,cj in pairs( trailer.componentJoints ) do
					if thisN[cj.componentIndices[1]] and not ( allN[cj.componentIndices[2]] ) then
						table.insert( nextN, cj.componentIndices[2] )
						if cj.rotLimit[2] > math.rad( 0.1 ) then
							table.insert( taJoints, index,
														{ nodeVehicle  = trailer.components[cj.componentIndices[1]].node,
															nodeTrailer  = trailer.components[cj.componentIndices[2]].node, 
															targetFactor = 1 } )
						end
					end
					if thisN[cj.componentIndices[2]] and not ( allN[cj.componentIndices[1]] ) then
						table.insert( nextN, cj.componentIndices[1] )
						if cj.rotLimit[2] > math.rad( 0.1 ) then
							table.insert( taJoints, index,
														{ nodeVehicle  = trailer.components[cj.componentIndices[2]].node,
															nodeTrailer  = trailer.components[cj.componentIndices[1]].node, 
															targetFactor = 1 } )
						end
					end
				end
			end
		end
	end	

	return taJoints 
end




------------------------------------------------------------------------
-- Cultivator -> FrontPacker
------------------------------------------------------------------------
function AutoSteeringEngine.registerFrontPacker( cultivator )
	if not ( ASEFrontPackerT[cultivator] ) then
		ASEFrontPackerT[cultivator] = true
		ASEFrontPackerC = ASEFrontPackerC + 1
	end
end

function AutoSteeringEngine.unregisterFrontPacker( cultivator )
	if ASEFrontPackerT[cultivator] then
		ASEFrontPackerT[cultivator] = false
		ASEFrontPackerC = math.max( 0, ASEFrontPackerC - 1 )
	end
end

function AutoSteeringEngine.resetFrontPacker( vehicle )
	if vehicle == nil then
		ASEFrontPackerT = {}
		ASEFrontPackerC = 0
	elseif ASEFrontPackerC > 0 and vehicle.attachedImplements ~= nil then
		for _, implement in pairs(vehicle.attachedImplements) do
			if implement.object ~= nil and ASEFrontPackerT[implement.object] then
				AutoSteeringEngine.unregisterFrontPacker( implement.object )
				AutoSteeringEngine.resetFrontPacker( implement.object )
			end
		end
	end
end

function AutoSteeringEngine.hasFrontPacker( vehicle )
	if ASEFrontPackerC <= 0 or vehicle == nil then 
		return false 
	end
	if ASEFrontPackerT[vehicle] then
		return true
	end
	if vehicle.attachedImplements == nil then
		return false 
	end
	for _, implement in pairs(vehicle.attachedImplements) do
		if AutoSteeringEngine.hasFrontPacker( implement.object ) then
			return true
		end
	end
	return false
end

function AutoSteeringEngine:updateTickCultivator( superFunc, ... )
	if ASEFrontPackerC <= 0 then
		return superFunc( self, ... )
	end
	
	local backup = CultivatorAreaEvent
	if ASEFrontPackerT[self] then
		if FrontPackerAreaEvent == nil then
			print("Error in AutoSteeringEngine.updateTickCultivator : FrontPackerAreaEvent is nil!")
		else
			CultivatorAreaEvent = FrontPackerAreaEvent
		end
	end
	local state,result = pcall( superFunc, self, ... )
	CultivatorAreaEvent = backup
	if state then
		return result
	else
		print("Error in AutoSteeringEngine.updateTickCultivator : "..tostring(result))
	end
end

function AutoSteeringEngine:updateTickSowingMachine( superFunc, ... )
	if ASEFrontPackerC <= 0 then
		return superFunc( self, ... )
	end
	
	local vehicle = self.getRootAttacherVehicle(self)
	local backup  = self.useDirectPlanting
	if AutoSteeringEngine.hasFrontPacker( vehicle ) then
		self.useDirectPlanting = true
	end
	local state,result = pcall( superFunc, self, ... )
	self.useDirectPlanting = backup 
	if state then
		return result
	else
		print("Error in AutoSteeringEngine.updateTickSowingMachine : "..tostring(result))
	end
end

Cultivator.updateTick    = Utils.overwrittenFunction( Cultivator.updateTick, AutoSteeringEngine.updateTickCultivator )
--SowingMachine.updateTick = Utils.overwrittenFunction( SowingMachine.updateTick, AutoSteeringEngine.updateTickSowingMachine )

