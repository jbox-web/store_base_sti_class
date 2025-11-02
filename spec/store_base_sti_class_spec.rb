# frozen_string_literal: true

require 'spec_helper'

RSpec.describe StoreBaseSTIClass do
  describe 'methods' do
    describe 'ActiveRecord::Base.polymorphic_name' do
      context 'when store_base_sti_class is true (default for backward compatibility)' do
        it 'returns the parent class' do
          expect(ActiveRecord::Base.store_base_sti_class).to be true
          expect(SpecialPost.polymorphic_name).to eq 'Post'
        end
      end

      context 'when store_base_sti_class is false' do
        before do
          @old_store_base_sti_class = ActiveRecord::Base.store_base_sti_class
          ActiveRecord::Base.store_base_sti_class = false
        end

        after do
          ActiveRecord::Base.store_base_sti_class = @old_store_base_sti_class # rubocop:disable RSpec/InstanceVariable
        end

        it 'returns the actual class' do
          expect(ActiveRecord::Base.store_base_sti_class).to be false
          expect(SpecialPost.polymorphic_name).to eq 'SpecialPost'
        end
      end
    end
  end

  describe 'behavior' do
    before do
      @old_store_base_sti_class = ActiveRecord::Base.store_base_sti_class
      ActiveRecord::Base.store_base_sti_class = false
    end

    after do
      ActiveRecord::Base.store_base_sti_class = @old_store_base_sti_class # rubocop:disable RSpec/InstanceVariable
    end

    describe 'test_polymorphic_belongs_to_assignment_with_inheritance' do
      context 'when assigning a saved record' do
        let(:post) { SpecialPost.create(title: 'Budget Forecasts Bigger 2011 Deficit', body: 'the body') }
        let(:tagging) { Tagging.new }

        it do
          tagging.taggable = post
          expect(tagging.taggable_id).to eq post.id
          expect(tagging.taggable_type).to eq 'SpecialPost'
        end
      end

      context 'when assigning a new record' do
        let(:post) { SpecialPost.new(title: 'Budget Forecasts Bigger 2011 Deficit', body: 'the body') }
        let(:tagging) { Tagging.new }

        it do
          tagging.taggable = post
          expect(tagging.taggable_id).to be_nil
          expect(tagging.taggable_type).to eq 'SpecialPost'
        end
      end
    end

    describe 'test_polymorphic_has_many_create_model_with_inheritance' do
      let(:post) { SpecialPost.new(title: 'Budget Forecasts Bigger 2011 Deficit', body: 'the body') }
      let(:misc_tag) { Tag.create(name: 'Misc') }

      it do
        tagging = misc_tag.taggings.create(taggable: post)
        expect(tagging.taggable_type).to eq 'SpecialPost'

        post.reload
        expect(post.taggings).to eq [tagging]
      end
    end

    describe 'test_polymorphic_has_one_create_model_with_inheritance' do
      let(:post) { SpecialPost.new(title: 'Budget Forecasts Bigger 2011 Deficit', body: 'the body') }
      let(:misc_tag) { Tag.create(name: 'Misc') }

      it do
        tagging = misc_tag.create_tagging(taggable: post)
        expect(tagging.taggable_type).to eq 'SpecialPost'

        post.reload
        expect(post.tagging).to eq tagging
      end
    end

    describe 'polymorphic_has_many_create_via_association' do
      let(:tag) { SpecialTag.create!(name: 'Special') }

      it do
        tagging = tag.polytaggings.create!

        expect(tagging.polytag_type).to eq 'SpecialTag'
      end
    end

    describe 'polymorphic_has_many_through_create_via_association' do
      let(:tag) { SpecialTag.create!(name: 'Special') }

      it do
        tag.polytagged_posts.create!(title: 'To Be or Not To Be?', body: 'the body')

        expect(tag.polytaggings.first.polytag_type).to eq 'SpecialTag'
      end
    end

    describe 'include_polymorphic_has_one' do
      let(:post) { SpecialPost.create!(title: 'Budget Forecasts Bigger 2011 Deficit', body: 'the body') }
      let(:misc_tag) { Tag.create(name: 'Misc') }

      it do
        tagging = post.create_tagging(tag: misc_tag)

        new_post = Post.includes(:tagging).find(post.id)
        expect(assert_no_queries { new_post.tagging }).to eq tagging
      end
    end

    describe 'include_polymorphic_has_many' do
      let(:tag) { SpecialTag.create!(name: 'Special') }
      let(:post) { SpecialPost.create(title: 'Thinking', body: 'the body') }
      let(:special_post) { SpecialPost.create!(title: 'Budget Forecasts Bigger 2011 Deficit', body: 'the body') }

      it do
        tag.polytagged_posts << special_post
        tag.polytagged_posts << post

        new_tag = Tag.includes(:polytaggings).find(tag.id)
        expect(assert_no_queries { new_tag.polytaggings.size }).to eq 2
      end
    end

    describe 'include_polymorphic_has_many_through' do
      let(:tag) { SpecialTag.create!(name: 'Special') }
      let(:post) { SpecialPost.create(title: 'Thinking', body: 'the body') }
      let(:special_post) { SpecialPost.create!(title: 'Budget Forecasts Bigger 2011 Deficit', body: 'the body') }

      it do
        tag.polytagged_posts << special_post
        tag.polytagged_posts << post

        new_tag = Tag.includes(:polytagged_posts).find(tag.id)
        expect(assert_no_queries { new_tag.polytagged_posts.size }).to eq 2
      end
    end

    describe 'join_polymorhic_has_many' do
      let(:tag) { SpecialTag.create!(name: 'Special') }
      let(:post) { SpecialPost.create(title: 'Thinking', body: 'the body') }
      let(:special_post) { SpecialPost.create!(title: 'Budget Forecasts Bigger 2011 Deficit', body: 'the body') }

      it do
        tag.polytagged_posts << special_post
        tag.polytagged_posts << post

        expect(Tag.joins(:polytaggings).where('taggings.id' => tag.polytaggings.first.id, id: tag.id)).to_not be_nil
      end
    end

    describe 'join_polymorhic_has_many_through' do
      let(:tag) { SpecialTag.create!(name: 'Special') }
      let(:post) { SpecialPost.create(title: 'Thinking', body: 'the body') }
      let(:special_post) { SpecialPost.create!(title: 'Budget Forecasts Bigger 2011 Deficit', body: 'the body') }

      it do
        tag.polytagged_posts << special_post
        tag.polytagged_posts << post

        expect(Tag.joins(:polytagged_posts).where('posts.id' => tag.polytaggings.first.taggable_id, id: tag.id)).to_not be_nil
      end
    end

    describe 'has_many_through_polymorphic_has_one' do
      let(:author) { Author.create!(name: 'Bob') }
      let(:post) { Post.create!(title: 'Budget Forecasts Bigger 2011 Deficit', author: author, body: 'the body') }
      let(:special_post) { SpecialPost.create!(title: 'IBM Watsons Jeopardy play', author: author, body: 'the body') }
      let(:special_tag) { SpecialTag.create!(name: 'SpecialGeneral') }

      it do
        taggings = [post.taggings.create(tag: special_tag), special_post.taggings.create(tag: special_tag)]
        expect(author.tagging.sort_by(&:id)).to eq taggings.sort_by(&:id)
      end
    end

    describe 'has_many_polymorphic_with_source_type' do
      let(:tag) { SpecialTag.create!(name: 'Special') }
      let(:post) { SpecialPost.create(title: 'Thinking', body: 'the body') }
      let(:special_post) { SpecialPost.create!(title: 'Budget Forecasts Bigger 2011 Deficit', body: 'the body') }

      it do
        tag.polytagged_posts << special_post
        tag.polytagged_posts << post

        tag.save!
        tag.reload

        new_tag = Tag.find(tag.id)

        expect(new_tag.polytagged_posts.size).to eq 2
      end
    end

    describe 'test_polymorphic_has_many_through_with_double_sti_on_join_model' do
      let(:tag) { SpecialTag.create!(name: 'Special') }
      let(:post) { SpecialPost.create(title: 'Thinking', body: 'the body') }

      it do
        tag.polytagged_posts << post

        tag.reload

        expect(tag.polytaggings.size).to eq 1

        tagging = tag.polytaggings.first

        expect(tagging.polytag_type).to eq 'SpecialTag'
        expect(tagging.taggable_type).to eq 'SpecialPost'

        expect(tagging.polytag).to eq tag
        expect(tagging.taggable).to eq post
      end
    end

    describe 'join_association' do
      let(:tag) { SpecialTag.create!(name: 'Special') }

      it do
        tag.polytaggings << Tagging.new
        expect(SpecialTag.joins(:polytaggings).where(id: tag.id).first).to_not be_nil
      end
    end

    describe 'where_query' do
      let(:tag) { SpecialTag.create!(name: 'Special') }
      let(:post) { SpecialPost.create(title: 'Thinking', body: 'the body') }

      it do
        tag.polytagged_posts << post
        expect(Tagging.where(taggable: post).size).to eq 1
      end
    end
  end
end
