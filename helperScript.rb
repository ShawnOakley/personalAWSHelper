require 'json'
require 'aws-sdk'

json = File.open('../AWS.json').read
configHash = JSON.parse(json)

supportedStructures = ['ec2','s3','dynamoDB']

AWSkey = configHash["AWSAccessKey"]
AWSsecret = configHash["AWSSecretKey"]
defaultRegion = configHash["defaultRegion"]


def initializeClient(configHash)
	AWS.config(access_key_id: configHash["AWSAccessKey"], secret_access_key: configHash["AWSSecretKey"], region: configHash["defaultRegion"])
end

def clientCreator(clientType, configHash)

	case clientType

	end

end

def optionsParser(optionsHash)

end

def s3creation(initializationHash)
	
end

def ec2creation(initializationHash)
	ec2 = AWS.ec2

end

def checkS3buckets(configHash)

end

def checkEC2(configHash)

end

def summarizeStates(configHash)

	supportedStructures.each do |struct|

	end

end

initializeClient(configHash)