require 'json'
require 'aws-sdk'

json = File.open('../AWS.json').read
configHash = JSON.parse(json)
@supportedStructures = ['EC2', 'dynamoDB', 'S3']

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
	@currentClients[struct] = nil;
end

def initializeClient(formattedConfigHash)
	AWS.config(formattedConfigHash)
end

def clientCreator(clientType, formattedConfigHash = nil)
	if !structureSupported?(clientType)
		raise "Specified client not supported."
	end

	if @currentClients[clientType]
		return @currentClients[clientType]
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

	@currentClients[clientType] = client
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

def checkInstances(clientType)
	#handle the various types of calls to return instance info
	#depends on type of client
	if !@currentClients[clientType]
		clientCreator(clientType)
	end

	case clientType

	when "ec2"
		checkEC2Instances
	when "dynamoDB"
		checkDynamoDBInstances
	when "s3"
		checkS3Instances
	else
		raise "The specified client type is not currently supported."
	end
end

def checkDynamoDBInstances
	return currentClients['dynamoDB'].tables
end

def checkEC2Instances
	return currentClients['EC2'].instances
end

def checkS3Instances
	return currentClients['S3'].buckets
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