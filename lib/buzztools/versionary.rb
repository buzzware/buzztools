# Versionary is a gem for implementing versioning of models with ActiveRecord in Rails 3.2+
# It attempts to be better than other solutions eg.
#
# * no shadow tables
# * does not abuse ActiveRecord
# * no serialization at all, so queries work with all versions
# * associations work like normal ActiveRecord
#
# This is achieved by using the id column to identify each version of each instance, unlike some solutions that use the id per instance, then have to do trickery to provide versions.
# This means associations can simply attach to any version of any instance using the id column as normal
# Instances are identified by the super_id column
#
# id    super_id  version   name  price
# 1     3         1         eggs  2.99
# 2     3         2         eggs  3.10
# 3     4         1         bread 3.50
#
# In the above table, eggs (super_id = 3) has 2 versions and bread (super_id = 4) has 1 version.
# An order can simply attach to any product/version using the id column
#
module Versionary

	def self.included(aClass)
    aClass.class_eval do

	    def self.next_version_id(aSuperId)
	   		where(super_id: aSuperId).maximum(:version).to_i + 1
	   	end

	    after_create do
	   		updates = {}
	   		updates[:super_id] = id if !super_id
	   		updates[:version] = self.class.next_version_id(self.super_id) if !version
	   		update_attributes!(updates) unless updates.empty?
	   		true
	   	end

			# should be able to do eg. : TaxRate.where(owner_id: 1,dealership_id: 2).latest_versions.where(state: 'WA')
			scope :latest_versions, -> {
				inner = clone.select("super_id, max(version) as version").group(:super_id).to_sql
				ids = ActiveRecord::Base.connection.execute("select id from (#{inner}) as v inner join #{table_name} as t on t.super_id = v.super_id and t.version = v.version").to_a.flatten.join(',')
				#ids = ActiveRecord::Base.connection.execute("select id from (SELECT super_id, max(version) as version FROM `things` GROUP BY super_id) as v inner join things as t on t.super_id = v.super_id and t.version = v.version").to_a.flatten.join(',')
				where "id IN (#{ids})"
			}

			scope :versions_valid_at, ->(aDate) {
				inner = clone.select("super_id, valid_from, max(version) as version").where("valid_from <= '#{aDate}'").group(:super_id).to_sql
				ids = ActiveRecord::Base.connection.execute("select id from (#{inner}) as v inner join #{table_name} as t on t.super_id = v.super_id and t.version = v.version").to_a.flatten.join(',')
				where "id IN (#{ids})"
			}

    end
  end

	#self.alias_method_chain :create!, :versioning
	#def self.create!(*args)
	#	begin
	#		super
	#	rescue ActiveRecord::RecordNotUnique => e
	#		raise unless e.original_exception.message =~ /index_[a-zA-Z0-9_]+_on_super_id_and_version'$/
	#		fields = args.first
	#		key = fields.has_key?('super_id') ? 'super_id' : :super_id
	#		super_id = fields[key]
	#		new_version = where(super_id: super_id).maximum(:version).to_i + 1
	#		key = fields.has_key?('version') ? 'version' : :version
	#		fields[key] = new_version
	#		super(*args)
	#	end
	#end

	def copyable_attributes
		result = {}
		self.class.columns.each do |c|
			next if ['id', 'version'].include? c.name
			result[c.name.to_sym] = self.send(c.name)
		end
		result
	end

	def new_version(aValues)
		raise "super_id must be set before calling new_version" unless self.super_id
		attrs = copyable_attributes
		attrs[:version] = self.class.next_version_id(self.super_id)
		ver = self.class.new(attrs)
		ver
	end

	def create_version!(aValues)
		raise "super_id must be set before calling new_version" unless self.super_id
		attrs = copyable_attributes
		attrs[:version] = self.class.next_version_id(self.super_id)
		attrs.merge!(aValues.symbolize_keys)
		self.class.create!(attrs)
	end

end