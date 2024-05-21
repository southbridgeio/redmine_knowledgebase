require 'active_record'

# module ActiveRecord #:nodoc:
module RedmineKnowledgebase
  module Acts #:nodoc:
    module Taggable #:nodoc:
      def self.included(base)
        base.extend(ClassMethods)
      end

      module ClassMethods

        def taggable?
          false
        end

        def acts_as_taggable
          has_many :taggings, :as => :taggable, :dependent => :destroy, :class_name => '::RedmineCrm::Tagging'#, :include => :tag
          has_many :tags, :through => :taggings, :class_name => '::RedmineCrm::Tag'

          before_save :save_cached_tag_list

          after_create :save_tags
          after_update :save_tags

          include RedmineKnowledgebase::Acts::Taggable::InstanceMethods
          extend RedmineKnowledgebase::Acts::Taggable::SingletonMethods

          alias_method :reload, :tag_list

          class_eval do
            def self.taggable?
              true
            end
          end
        end

        def cached_tag_list_column_name
          "cached_tag_list"
        end

        def set_cached_tag_list_column_name(value = nil, &block)
          define_attr_method :cached_tag_list_column_name, value, &block
        end

        # Create the taggable tables
        # === Options hash:
        # * <tt>:table_name</tt> - use a table name other than viewings
        # To be used during migration, but can also be used in other places
        def create_taggable_table options = {}
          tag_name_table      = options[:tags] || :tags

          if !self.connection.table_exists?(tag_name_table)
            self.connection.create_table(tag_name_table) do |t|
              t.column :name, :string
            end
          end

          taggings_name_table = options[:taggings] || :taggings
          if !self.connection.table_exists?(taggings_name_table)
            self.connection.create_table(taggings_name_table) do |t|
              t.column :tag_id, :integer
              t.column :taggable_id, :integer

              # You should make sure that the column created is
              # long enough to store the required class names.
              t.column :taggable_type, :string

              t.column :created_at, :datetime
            end

            self.connection.add_index :taggings, :tag_id
            self.connection.add_index :taggings, [:taggable_id, :taggable_type]
          end

        end

        def drop_taggable_table options = {}
          tag_name_table      = options[:tags] || :tags
          if self.connection.table_exists?(tag_name_table)
            self.connection.drop_table tag_name_table
          end
          taggings_name_table = options[:taggings] || :taggings
          if self.connection.table_exists?(taggings_name_table)
            self.connection.drop_table taggings_name_table
          end

        end
      end

      module SingletonMethods
        #Return all avalible tags for a project or global
        #Example: Question.available_tags(@project_id )
        def available_tags(project=nil, limit=30)
          scope = RedmineCrm::Tag.where({})
          class_name = "'#{base_class.name}'"
          join = []
          join << "JOIN #{RedmineCrm::Tagging.table_name} ON #{RedmineCrm::Tagging.table_name}.tag_id = #{RedmineCrm::Tag.table_name}.id "
          join << "JOIN #{table_name} ON #{table_name}.id = #{RedmineCrm::Tagging.table_name}.taggable_id
            AND #{RedmineCrm::Tagging.table_name}.taggable_type = #{class_name} "
          if self.attribute_names.include? "project_id"
            if project
              join << "JOIN #{Project.table_name} ON #{Project.table_name}.id = #{table_name}.project_id"
            else
              scope = scope.where("#{table_name}.project_id IS NULL")
            end
          end

          group_fields = ""
          group_fields << ", #{RedmineCrm::Tag.table_name}.created_at" if RedmineCrm::Tag.respond_to?(:created_at)
          group_fields << ", #{RedmineCrm::Tag.table_name}.updated_at" if RedmineCrm::Tag.respond_to?(:updated_at)

          scope = scope.joins(join.join(' '))
          scope = scope.select("#{RedmineCrm::Tag.table_name}.*, COUNT(DISTINCT #{RedmineCrm::Tagging.table_name}.taggable_id) AS count")
          scope = scope.group("#{RedmineCrm::Tag.table_name}.id, #{RedmineCrm::Tag.table_name}.name #{group_fields} HAVING COUNT(*) > 0")
          scope = scope.order("#{RedmineCrm::Tag.table_name}.name")
          scope = scope.limit(limit) if limit
          scope
        end
        # Returns an array of related tags.
        # Related tags are all the other tags that are found on the models tagged with the provided tags.
        #
        # Pass either a tag, string, or an array of strings or tags.
        #
        # Options:
        #   :order - SQL Order how to order the tags. Defaults to "count DESC, tags.name".
        def find_related_tags(tags, options = {})
          tags = tags.is_a?(Array) ? RedmineCrm::TagList.new(tags.map(&:to_s)) : RedmineCrm::TagList.from(tags)

          related_models = find_tagged_with(tags)

          return [] if related_models.blank?

          related_ids = related_models.map{|c| c.id }.join(",")
          RedmineCrm::Tag.select( #find(:all, options.merge({
            "#{RedmineCrm::Tag.table_name}.*, COUNT(#{RedmineCrm::Tag.table_name}.id) AS count").joins(
            "JOIN #{RedmineCrm::Tagging.table_name} ON #{RedmineCrm::Tagging.table_name}.taggable_type = '#{base_class.name}'
              AND  #{RedmineCrm::Tagging.table_name}.taggable_id IN (#{related_ids})
              AND  #{RedmineCrm::Tagging.table_name}.tag_id = #{RedmineCrm::Tag.table_name}.id").order(
            options[:order] || "count DESC, #{RedmineCrm::Tag.table_name}.name").group(
            "#{RedmineCrm::Tag.table_name}.id, #{RedmineCrm::Tag.table_name}.name HAVING #{RedmineCrm::Tag.table_name}.name NOT IN (#{tags.map { |n| quote(n) }.join(",")})")
          # }))
        end

        def quote(v)
          "'#{v}'"
        end

        # Pass either a tag, string, or an array of strings or tags.
        #
        # Options:
        #   :exclude - Find models that are not tagged with the given tags
        #   :match_all - Find models that match all of the given tags, not just one
        #   :conditions - A piece of SQL conditions to add to the query
        def find_tagged_with(*args)
          options = find_options_for_find_tagged_with(*args)
          options.blank? ? [] : select(options[:select]).where(options[:conditions]).joins(options[:joins]).order(options[:order]).to_a
          # find(:all, options)
        end
        alias_method :tagged_with, :find_tagged_with

        def find_options_for_find_tagged_with(tags, options = {})
          tags = tags.is_a?(Array) ? RedmineCrm::TagList.new(tags.map(&:to_s)) : RedmineCrm::TagList.from(tags)
          options = options.dup

          return {} if tags.empty?

          conditions = []
          conditions << sanitize_sql(options.delete(:conditions)) if options[:conditions]

          taggings_alias, tags_alias = "#{table_name}_taggings", "#{table_name}_tags"

          joins = [
            "INNER JOIN #{RedmineCrm::Tagging.table_name} #{taggings_alias} ON #{taggings_alias}.taggable_id = #{table_name}.#{primary_key} AND #{taggings_alias}.taggable_type = '#{base_class.name}'",
            "INNER JOIN #{RedmineCrm::Tag.table_name} #{tags_alias} ON #{tags_alias}.id = #{taggings_alias}.tag_id"
          ]

          if options.delete(:exclude)
            conditions << <<-END
              #{table_name}.id NOT IN
                (SELECT #{RedmineCrm::Tagging.table_name}.taggable_id FROM #{RedmineCrm::Tagging.table_name}
                 INNER JOIN #{RedmineCrm::Tag.table_name} ON #{RedmineCrm::Tagging.table_name}.tag_id = #{RedmineCrm::Tag.table_name}.id
                 WHERE #{tags_condition(tags)} AND #{RedmineCrm::Tagging.table_name}.taggable_type = #{"'#{base_class.name}'"})
            END
          else
            if options.delete(:match_all)
              joins << joins_for_match_all_tags(tags)
            else
              conditions << tags_condition(tags, tags_alias)
            end
          end

          { :select => "DISTINCT #{table_name}.* ",
            :joins => joins.join(" "),
            :conditions => conditions.join(" AND ")
          }.reverse_merge!(options)
        end

        def joins_for_match_all_tags(tags)
          joins = []

          tags.each_with_index do |tag, index|
            taggings_alias, tags_alias = "taggings_#{index}", "tags_#{index}"

            join = <<-END
              INNER JOIN #{RedmineCrm::Tagging.table_name} #{taggings_alias} ON
                #{taggings_alias}.taggable_id = #{table_name}.#{primary_key} AND
                #{taggings_alias}.taggable_type = '#{base_class.name}'

              INNER JOIN #{RedmineCrm::Tag.table_name} #{tags_alias} ON
                #{taggings_alias}.tag_id = #{tags_alias}.id AND
                #{tags_alias}.name = ?
            END

            joins << sanitize_sql([join, tag])
          end

          joins.join(" ")
        end

        # Calculate the tag counts for all tags.
        #
        # See Tag.counts for available options.
        def tag_counts(options = {})
          # Tag.find(:all, find_options_for_tag_counts(options))
          opt = find_options_for_tag_counts(options)
          RedmineCrm::Tag.select(opt[:select]).where(opt[:conditions]).joins(opt[:joins]).group(opt[:group]).having(opt[:having]).order(opt[:order]).limit(options[:limit])
        end
        alias_method :all_tag_counts, :tag_counts

        def find_options_for_tag_counts(options = {})
          options = options.dup
          scope = scope_attributes

          conditions = []
          conditions << options.delete(:conditions) if options[:conditions]
          conditions << scope if scope

          conditions << "#{RedmineCrm::Tagging.table_name}.taggable_type = '#{base_class.name}'"
          conditions << type_condition unless descends_from_active_record?
          conditions.compact!

          # Convert conditions to a sanitized SQL condition string
          sql_conditions = conditions.map do |condition|
            if condition.is_a?(String)
              condition
            elsif condition.is_a?(Hash)
              condition.map do |key, value|
                key = "#{KbArticle.table_name}.#{key}" if key.to_s == "id"
                sanitize_sql(["#{key} = ?", value])
              end.join(' AND ')
            else
              send(:sanitize_sql, condition)
            end
          end.compact.find_all {|cond| cond.present? }.join(' AND ')

          joins = ["INNER JOIN #{table_name} ON #{table_name}.#{primary_key} = #{RedmineCrm::Tagging.table_name}.taggable_id"]
          joins << options.delete(:joins) if options[:joins].present?
          joins = joins.join(' ')

          options = { conditions: sql_conditions, joins: joins }.merge(options)

          RedmineCrm::Tag.options_for_counts(options)
        end

        def caching_tag_list?
          column_names.include?(cached_tag_list_column_name)
        end

        private
        def tags_condition(tags, table_name = RedmineCrm::Tag.table_name)
          condition = tags.map { |t| sanitize_sql(["#{table_name}.name LIKE ?", t]) }.join(" OR ")
          "(" + condition + ")" unless condition.blank?
        end

        def merge_conditions(*conditions)
          segments = []

          conditions.each do |condition|
            unless condition.blank?
              sql = sanitize_sql(condition)
              segments << sql unless sql.blank?
            end
          end

          "(#{segments.join(') AND (')})" unless segments.empty?
        end
      end

      module InstanceMethods
        def tag_list
          return @tag_list if @tag_list

          if self.class.caching_tag_list? and !(cached_value = send(self.class.cached_tag_list_column_name)).nil?
            @tag_list = RedmineCrm::TagList.from(cached_value)
          else
            @tag_list = RedmineCrm::TagList.new(*tags.map(&:name))
          end
        end

        def tag_list=(value)
          @tag_list = RedmineCrm::TagList.from(value)
        end

        def save_cached_tag_list
          if self.class.caching_tag_list?
            self[self.class.cached_tag_list_column_name] = tag_list.to_s
          end
        end

        #build list from related tags
        def all_tags_list
          tags.pluck(:name)
        end

        def save_tags
          return unless @tag_list

          new_tag_names = @tag_list - tags.map(&:name)
          old_tags = tags.reject { |tag| @tag_list.include?(tag.name) }

          self.class.transaction do
            if old_tags.any?
              taggings.where("tag_id IN (?)", old_tags.map(&:id)).each(&:destroy)
              taggings.reset
            end
            new_tag_names.each do |new_tag_name|
              tags << RedmineCrm::Tag.find_or_create_with_like_by_name(new_tag_name)
            end
          end

          true
        end

        # Calculate the tag counts for the tags used by this model.
        #
        # The possible options are the same as the tag_counts class method.
        def tag_counts(options = {})
          return [] if tag_list.blank?

          options[:conditions] = self.class.send(:merge_conditions, options[:conditions], self.class.send(:tags_condition, tag_list))
          self.class.tag_counts(options)
        end

        def reload_with_tag_list(*args) #:nodoc:
          @tag_list = nil
          reload_without_tag_list(*args)
        end
      end
    end
  end
end
