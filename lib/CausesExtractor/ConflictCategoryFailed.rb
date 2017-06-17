require 'require_all'
require_rel 'ConflictCategories'

class ConflictCategoryFailed
	include ConflictCategories

	def initialize()
		@gitProblem = 0
		@remoteError = 0
		@otherError = 0
		@permission = 0
		@failed = 0
	end

	def getGitProblem()
		@gitProblem
	end

	def getRemoteError()
		@remoteError
	end

	def getOtherError()
		@otherError
	end

	def getPermission()
		@permission
	end

	def getFailed()
		@failed
	end

	def getTotal()
		return getGitProblem() + getRemoteError() + getFailed() + getOtherError() + getPermission()
	end

	def findConflictCauseFork(logs)
		result = ""
		logs.each do |log|
			result = getCauseByJob(log)
		end
		return log
	end

	def findConflictCause(build)
		result = ""
		indexJob = 0
		while (indexJob < build.job_ids.size)
			if (build.jobs[indexJob].state == "failed")
				if (build.jobs[indexJob].log != nil)
					build.jobs[indexJob].log.body do |part|
						result = getCauseByJob(part)
					end
				end
			end
			indexJob += 1
		end
		return result
	end

	def getCauseByJob(log)
		stringBuildFail = "FAILURE"
		stringNoOutput = "No output has been received"
		stringTerminated = "The build has been terminated"
		stringTheCommand = "The command "
		result = ""
		if (log[/Errors: [0-9]*/])
			@failed += 1
			result = "failed"
		elsif (log[/#{stringBuildFail}\s*([^\n\r]*)\s*([^\n\r]*)\s*([^\n\r]*)failed/] || part[/#{stringTheCommand}("mvn|"\.\/mvnw)+(.*)failed(.*)/])
			@failed += 1
			result = "failed"
		elsif (log[/#{stringTheCommand}("git clone |"git checkout)(.*?)failed(.*)[\n]*/])
			@gitProblem += 1
			result = "gitProblem"
		elsif (log[/#{stringNoOutput}(.*)wrong(.*)[\n]*#{stringTerminated}/])
			@remoteError += 1
			result = "remoteError"
		elsif (log[/#{stringTheCommand}("cd|"sudo|"echo|"eval)+ (.*)failed(.*)/])
			@permission += 1
			result = "permission"
		else
			@otherError += 1
			result = "otherError"
		end
		return result
	end
end