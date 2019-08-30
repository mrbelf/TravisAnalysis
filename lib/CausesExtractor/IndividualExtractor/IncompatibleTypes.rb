class IncompatibleTypes

	def initialize()
		
	end

	def extractionFilesInfo(buildLog)
		filesInformation = []
		logs = buildLog.to_enum(:scan, /^[\--z]+:\d+: error: incompatible types: \w+ cannot be converted to \w+$/).map { Regexp.last_match }
		begin
			if (buildLog[/^[\--z]+:\d+: error: incompatible types: \w+ cannot be converted to \w+$/])
				count = 0
				while (count < logs.size)
					line = logs[count].to_s[/\.java:\d+/].split(":").last
					classFile = logs[count].to_s[/[\/\-\_\w]+\.java:/].split("/").last.gsub(".java:","")
					typeAndExpected = logs[count].to_s[/\w+ cannot be converted to \w+/].to_s.split(" ")
					type = typeAndExpected[0]
					expectedType = typeAndExpected[5]
					filesInformation.push(["IncompatibleTypes",classFile, type, expectedType,line])
					count += 1
				end
			end		
			return "IncompatibleTypes", filesInformation, logs.size
		rescue
			return "IncompatibleTypes", [], 0
		end
	end

end
