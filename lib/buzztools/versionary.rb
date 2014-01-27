# Versionary is a mixin for implementing versioning of models with ActiveRecord in Rails 3.2+
# It attempts to be better than other solutions eg.
#
# * no shadow tables
# * does not abuse ActiveRecord, no magic
# * no serialization at all, so queries work with all versions
# * associations work like normal ActiveRecord
# * its easy to read and write old versions
#
# This is achieved by using the id column to identify each version of each instance, unlike some solutions that use the id per instance, then have to do trickery to provide versions.
# This means associations can simply attach to any version of any instance using the id column as normal
# Instances are identified by the iid column
#
# id    iid  version   name  price
# 1     3         1         eggs  2.99
# 2     3         2         eggs  3.10
# 3     4         1         bread 3.50
#
# In the above table, eggs (iid = 3) has 2 versions and bread (iid = 4) has 1 version.
# An order can simply attach to any product/version using the id column
#
# The eggs product would be created as follows :
#
# eggs = Product.create!(name: 'eggs', price: 2.99)
# eggs2 = eggs.create_version!(price: 3.10)
#
# latest_eggs = Product.where(name: 'eggs').latest_versions.first
#
# Migration
#
#class CreateThings < ActiveRecord::Migration
#  def change
#    create_table :things do |t|
#      t.integer :iid
#      t.integer :version
#      t.date :current_from
#      t.integer :size
#      t.string :colour
#      t.string :shape
#    end
#		add_index(:things, [:iid, :version], :unique => true)
#  end
#end
#
# Model
#
#class Thing < ActiveRecord::Base
#
#	include Versionary
#
#end
#
#
module Versionary

	def self.included(aClass)
    aClass.class_eval do

	    def self.next_version_id(aIid)
	   		where(iid: aIid).maximum(:version).to_i + 1
	   	end

	    # as an optimisation :
	    # * add ver_is_max column and max_version_instance_id(iid) method
	    # * set ver_is_max on after_create
	    # * can then read max_versions very quickly (where ver_is_max = TRUE)
	    #
	    # * add ver_current columns and set on create if id == current_version_instance_id(iid)
	    # * every so often, must run update_current_version_column method
	    # * can then read current_versions very quickly (eg. where ver_current = TRUE)
	    after_create do
	   		updates = {}
	   		updates[:iid] = id if !iid
		    if !version
	   		  updates[:version] = self.class.next_version_id(self.iid)
		      updates[:ver_latest] = true
		    end
	   		update_attributes!(updates) unless updates.empty?
	   		true
	   	end

			# should be able to do eg. : TaxRate.where(owner_id: 1,dealership_id: 2).latest_versions.where(state: 'WA')
			scope :live_latest_versions, -> {
				inner = clone.select("iid, max(version) as version").group(:iid).to_sql
				ids = ActiveRecord::Base.connection.execute("select id from (#{inner}) as v inner join #{table_name} as t on t.iid = v.iid and t.version = v.version").to_a.flatten.join(',')
				#ids = ActiveRecord::Base.connection.execute("select id from (SELECT iid, max(version) as version FROM `things` GROUP BY iid) as v inner join things as t on t.iid = v.iid and t.version = v.version").to_a.flatten.join(',')
				where "id IN (#{ids})"
			}

	    # update_current_version_column would :
	    # clear all flags
	    # use live_current_versions and latest_versions to get rows
	    # set flags on selected rows
	    #Thing.update_all(:ver_latest,false)
	    #Thing.live_latest_versions.update_all(:ver_latest,true)

	    # select unique iid's
	    # for each iid, v = Model.live_current_version(iid,aDate)

	    ## Thing.select("...").where(owner: ,dealership: ).latest_versions.where(state: 'WA')
	    #scope :latest_versions, -> {
		   # inner = clone.select("iid, max(version) as version").group(:iid).to_sql
       # from("#{inner} as v").join("inner join #{table_name} as t on t.iid = v.iid and t.version = v.version")
       # #
       # #ids = ActiveRecord::Base.connection.execute("select id from (#{inner}) as v inner join #{table_name} as t on t.iid = v.iid and t.version = v.version").to_a.flatten.join(',')
       # ##ids = ActiveRecord::Base.connection.execute("select id from (SELECT iid, max(version) as version FROM `things` GROUP BY iid) as v inner join things as t on t.iid = v.iid and t.version = v.version").to_a.flatten.join(',')
       # #where "id IN (#{ids})"
	 		#}


			scope :live_current_versions, ->(aDate) {
				inner = clone.select("iid, current_from, max(version) as version").where("current_from <= '#{aDate}'").group(:iid).to_sql
				ids = ActiveRecord::Base.connection.execute("select id from (#{inner}) as v inner join #{table_name} as t on t.iid = v.iid and t.version = v.version").to_a.flatten.join(',')
				where "id IN (#{ids})"
			}

	    scope :live_current_version, ->(aIid,aDate) {
		    where(iid: aIid).where("current_from <= '#{aDate}'").order('version DESC').limit(1)
	    }

	    scope :latest_version, -> {
		    where(ver_latest: true)
	    }

	    scope :current_versions, ->(aDate) {
		    where(ver_current: true)
	    }
    end
  end

	#self.alias_method_chain :create!, :versioning
	#def self.create!(*args)
	#	begin
	#		super
	#	rescue ActiveRecord::RecordNotUnique => e
	#		raise unless e.original_exception.message =~ /index_[a-zA-Z0-9_]+_on_iid_and_version'$/
	#		fields = args.first
	#		key = fields.has_key?('iid') ? 'iid' : :iid
	#		iid = fields[key]
	#		new_version = where(iid: iid).maximum(:version).to_i + 1
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
		raise "iid must be set before calling new_version" unless self.iid
		attrs = copyable_attributes
		attrs[:version] = self.class.next_version_id(self.iid)
		ver = self.class.new(attrs)
		ver
	end

	def create_version!(aValues)
		raise "iid must be set before calling new_version" unless self.iid
		attrs = copyable_attributes
		attrs[:version] = self.class.next_version_id(self.iid)
		attrs.merge!(aValues.symbolize_keys)
		self.class.create!(attrs)
	end

end