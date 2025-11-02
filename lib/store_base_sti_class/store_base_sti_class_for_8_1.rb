# frozen_string_literal: true

if ActiveRecord::VERSION::STRING =~ /\A8\.1/
  module StoreBaseSTIClass
    module Inheritance
      module ClassMethodsPatch
        # See: https://github.com/rails/rails/blob/v8.1.0/activerecord/lib/active_record/inheritance.rb#L211
        def polymorphic_name
          ActiveRecord::Base.store_base_sti_class ? base_class.name : name
        end
      end
    end

    module Associations
      module Preloader
        module ThroughAssociationPatch
          private

          # See: https://github.com/rails/rails/blob/v8.1.0/activerecord/lib/active_record/associations/preloader/through_association.rb#L104
          def through_scope
            scope = through_reflection.klass.unscoped
            options = reflection.options

            return scope if options[:disable_joins]

            values = reflection_scope.values
            if annotations = values[:annotate]
              scope.annotate!(*annotations)
            end

            if options[:source_type]
              # BEGIN PATCH
              # original:
              # scope.where! reflection.foreign_type => options[:source_type]

              adjusted_foreign_type =
                if ActiveRecord::Base.store_base_sti_class
                  options[:source_type]
                else
                  ([options[:source_type].constantize] + options[:source_type].constantize.descendants).map(&:to_s)
                end

              scope.where! reflection.foreign_type => adjusted_foreign_type
              # END PATCH

            elsif !reflection_scope.where_clause.empty?
              scope.where_clause = reflection_scope.where_clause

              if includes = values[:includes]
                scope.includes!(source_reflection.name => includes)
              else
                scope.includes!(source_reflection.name)
              end

              if values[:references] && !values[:references].empty?
                scope.references_values |= values[:references]
              else
                scope.references!(source_reflection.table_name)
              end

              if joins = values[:joins]
                scope.joins!(source_reflection.name => joins)
              end

              if left_outer_joins = values[:left_outer_joins]
                scope.left_outer_joins!(source_reflection.name => left_outer_joins)
              end

              if scope.eager_loading? && order_values = values[:order]
                scope = scope.order(order_values)
              end
            end

            cascade_strict_loading(scope)
          end
        end
      end

      module AssociationScopePatch
        private

        # See: https://github.com/rails/rails/blob/v8.1.0/activerecord/lib/active_record/associations/association_scope.rb#L81
        def next_chain_scope(scope, reflection, next_reflection)
          primary_key = Array(reflection.join_primary_key)
          foreign_key = Array(reflection.join_foreign_key)

          table = reflection.aliased_table
          foreign_table = next_reflection.aliased_table

          primary_key_foreign_key_pairs = primary_key.zip(foreign_key)
          constraints = primary_key_foreign_key_pairs.map do |join_primary_key, foreign_key|
            table[join_primary_key].eq(foreign_table[foreign_key])
          end.inject(&:and)

          if reflection.type
            # BEGIN PATCH
            # original:
            # value = transform_value(next_reflection.klass.polymorphic_name)
            # scope = apply_scope(scope, table, reflection.type, value)

            if ActiveRecord::Base.store_base_sti_class
              value = transform_value(next_reflection.klass.polymorphic_name)
            else
              klass = next_reflection.klass
              value = ([klass] + klass.descendants).map(&:name)
            end
            scope = apply_scope(scope, table, reflection.type, value)
            # END PATCH
          end

          scope.joins!(join(foreign_table, constraints))
        end
      end

      module HasManyThroughAssociationPatch
        private

        # See: https://github.com/rails/rails/blob/v8.1.0/activerecord/lib/active_record/associations/has_many_through_association.rb#L56
        def build_through_record(record)
          @through_records[record] ||= begin
            ensure_mutable

            attributes = through_scope_attributes
            attributes[source_reflection.name] = record

            through_association.build(attributes).tap do |new_record|
              if ActiveRecord::Base.store_base_sti_class
                new_record.send("#{source_reflection.foreign_type}=", options[:source_type]) if options[:source_type]
              end
            end
          end
        end
      end
    end

    module Reflection
      module PolymorphicReflectionPatch
        private

        # See: https://github.com/rails/rails/blob/v8.1.0/activerecord/lib/active_record/reflection.rb#L1286
        def source_type_scope
          type = @previous_reflection.foreign_type
          source_type = @previous_reflection.options[:source_type]

          # START PATCH
          adjusted_source_type =
            if ActiveRecord::Base.store_base_sti_class
              source_type
            else
              ([source_type.constantize] + source_type.constantize.descendants).map(&:to_s)
            end
          # END PATCH

          lambda { |object| where(type => adjusted_source_type) }
        end
      end
    end
  end

  ActiveRecord::Inheritance::ClassMethods.prepend(StoreBaseSTIClass::Inheritance::ClassMethodsPatch)
  ActiveRecord::Associations::Preloader::ThroughAssociation.prepend(StoreBaseSTIClass::Associations::Preloader::ThroughAssociationPatch)
  ActiveRecord::Associations::AssociationScope.prepend(StoreBaseSTIClass::Associations::AssociationScopePatch)
  ActiveRecord::Associations::HasManyThroughAssociation.prepend(StoreBaseSTIClass::Associations::HasManyThroughAssociationPatch)
  ActiveRecord::Reflection::PolymorphicReflection.prepend(StoreBaseSTIClass::Reflection::PolymorphicReflectionPatch)

  ActiveRecord::Base.class_eval do
    # It defaults to true for backwards compatibility.
    # Setting it to false will alter ActiveRecord's behavior to store the actual class in `polymorphic_type` columns when STI is used.
    class_attribute :store_base_sti_class, default: true
  end
end
