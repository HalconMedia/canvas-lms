#
# Copyright (C) 2017 - present Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.
#

module Api::V1::PlannerItem
  include Api::V1::Json
  include Api::V1::Assignment
  include Api::V1::Quiz
  include Api::V1::Context
  include Api::V1::DiscussionTopics
  include Api::V1::WikiPage
  include Api::V1::PlannerOverride

  PLANNABLE_TYPES = {
    'discussion_topic' => 'DiscussionTopic',
    'announcement' => 'DiscussionTopic',
    'quiz' => 'Quizzes::Quiz',
    'assignment' => 'Assignment',
    'wiki_page' => 'WikiPage',
    'planner_note' => 'PlannerNote'
  }.freeze

  def planner_item_json(item, user, session, opts = {})
    context_data(item).merge({
      :plannable_id => item.id,
      :plannable_date => item.planner_date,
      :visible_in_planner => item.visible_in_planner_for?(user),
      :planner_override => planner_override_json(item.planner_override_for(user), user, session)
    }).merge(submission_statuses_for(user, item, opts)).tap do |hash|
      if item.is_a?(PlannerNote)
        hash[:plannable_type] = 'planner_note'
        hash[:plannable] = api_json(item, user, session)
        hash[:html_url] = api_v1_planner_notes_show_path(item)
      elsif item.is_a?(Quizzes::Quiz) || (item.respond_to?(:quiz?) && item.quiz?)
        quiz = item.is_a?(Quizzes::Quiz) ? item : item.quiz
        hash[:plannable_type] = 'quiz'
        hash[:plannable] = quiz_json(quiz, quiz.context, user, session)
        hash[:html_url] = named_context_url(quiz.context, :context_quiz_url, quiz.id)
        hash[:planner_override] ||= planner_override_json(quiz.planner_override_for(user), user, session)
      elsif item.is_a?(WikiPage) || (item.respond_to?(:wiki_page?) && item.wiki_page?)
        item = item.wiki_page if item.respond_to?(:wiki_page?) && item.wiki_page?
        hash[:plannable_type] = 'wiki_page'
        hash[:plannable] = wiki_page_json(item, user, session)
        hash[:html_url] = named_context_url(item.context, :context_wiki_page_url, item.id)
        hash[:planner_override] ||= planner_override_json(item.planner_override_for(user), user, session)
      elsif item.is_a?(Announcement)
        hash[:plannable_type] = 'announcement'
        hash[:plannable] = discussion_topic_api_json(item.discussion_topic, item.discussion_topic.context, user, session)
        hash[:html_url] = named_context_url(item.discussion_topic.context, :context_discussion_topic_url, item.discussion_topic.id)
      elsif item.is_a?(DiscussionTopic) || (item.respond_to?(:discussion_topic?) && item.discussion_topic?)
        topic = item.is_a?(DiscussionTopic) ? item : item.discussion_topic
        hash[:plannable_type] = 'discussion_topic'
        hash[:plannable] = discussion_topic_api_json(topic, topic.context, user, session)
        hash[:html_url] = named_context_url(topic.context, :context_discussion_topic_url, topic.id)
        hash[:planner_override] ||= planner_override_json(topic.planner_override_for(user), user, session)
      else
        hash[:plannable_type] = 'assignment'
        hash[:plannable] = assignment_json(item, user, session, include_discussion_topic: true)
        hash[:html_url] = named_context_url(item.context, :context_assignment_url, item.id)
      end
    end
  end

  def planner_items_json(items, user, session, opts = {})
    items.map do |item|
      planner_item_json(item, user, session, opts)
    end
  end

  def submission_statuses_for(user, item, opts = {})
    submission_status = {submissions: false}
    return submission_status unless item.is_a?(Assignment)
    ss = user.submission_statuses(opts)
    submission_status[:submissions] = {
      submitted: ss[:submitted].include?(item.id),
      excused: ss[:excused].include?(item.id),
      graded: ss[:graded].include?(item.id),
      late: ss[:late].include?(item.id),
      missing: ss[:missing].include?(item.id),
      needs_grading: ss[:needs_grading].include?(item.id),
      has_feedback: ss[:has_feedback].include?(item.id)
    }

    submission_status
  end

  def planner_override_json(override, user, session)
    return unless override.present?
    json = api_json(override, user, session)
    json['plannable_type'] = PLANNABLE_TYPES.key(json['plannable_type'])
    json
  end
end
