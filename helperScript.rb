require 'json'
require 'aws-sdk'

json = File.open('../AWS.json').read
configHash = JSON.parse(json)
@supportedStructures = ['ec2', 'dynamoDB', 's3']

# Create config hash for more readable code within functions

formattedConfigHash = {
  	access_key_id: configHash["AWSAccessKey"],
  	secret_access_key: configHash["AWSSecretKey"],
  	region:	configHash["defaultRegion"]
}

# May want an instance to track initialized clients
# Don't need ID b/c there should only be one instance of each type,
# as initialized
# E.g.: [{'clientType': 'EC2', 'clientInstance': client}]
# Initialize to nil
@supportedStructures.each do |struct|
	@currentObjects[struct] = nil;
end



def initializeClient(formattedConfigHash)
	AWS.config(formattedConfigHash)
end

def clientCreator(clientType, formattedConfigHash = nil)
	if !structureSupported?(clientType)
		raise "Specified client not supported."
	end

	case clientType

	when "ec2"
		client = ec2create(formattedConfigHash)
	when "dynamoDB"
		client  = dynamoDBcreate(formattedConfigHash)
	when "s3"
		client = s3create(formattedConfigHash)
	else
		raise "The specified client type is not currently supported."
	end

	return client

end

def optionsParser(optionsHash)

end

def dynamoDBcreate(formattedConfigHash)
	if !configExists?
		client = AWS::DynamoDB.new(formattedConfigHash)
	else 
		client = AWS::DynamoDB.new
	end
	return client
end

def s3create(formattedConfigHash)
	if !configExists?
		client = AWS::S3.new(formattedConfigHash)
	else 
		client = AWS::S3.new
	end
	return client
end

def ec2create(formattedConfigHash)
	if !configExists?
		client = AWS::EC2.new(formattedConfigHash)
	else 
		client = AWS::EC2.new
	end
end



def checkInstancesByType(clientType)
	if !structureSupported?(clientType)
		raise "Specified client type not supported."
	end
	client = clientCreator(clientType)
	instanceInfo = checkInstances(client)
	return instanceInfo
end

def checkInstances(client)
	#handle the various types of calls to return instance info
	#depends on type of client
end

def checkDynamoDBInstances(client)
	return client.tables
end

def checkEC2Instances(client)
	return client.instances
end

def checkS3Instances(client)
	return client.buckets
end


def checkStatusAll(configHash = nil)

	if !configExists? && (configHash == nil)
		raise "Client needs to be defined."
	end
	@supportedStructures.each do |struct|
		client = clientCreator(struct)
		checkInstances(client)
	end

end

# Helper functions to check current state of config/script capabilities

def configExists?
	return !!(AWS)
end

def structureSupported?(structure)
 return @supportedStructures.include?(structure)
end

initializeClient(configHash)
puts structureSupported?('ec2')