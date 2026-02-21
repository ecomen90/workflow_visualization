# plugins/workflow_visualization/app/controllers/workflow_visualizations_controller.rb

class WorkflowVisualizationsController < ApplicationController
  before_action :require_login
  before_action :require_admin, only: [:index]

  layout 'admin'

  # GET /workflow_visualization
  # 트래커 & 역할 선택 화면
  def index
    @trackers = Tracker.sorted
    @roles    = Role.givable.sorted
    @selected_tracker_id = params[:tracker_id].to_i
    @selected_role_id    = params[:role_id].to_i

    if @selected_tracker_id > 0 && @selected_role_id > 0
      @tracker = Tracker.find_by(id: @selected_tracker_id)
      @role    = Role.find_by(id: @selected_role_id)
      @graph_data = build_graph_data(@tracker, @role) if @tracker && @role
    end
  end

  # GET /workflow_visualization/show
  def show
    @tracker = Tracker.find(params[:tracker_id])
    @role    = Role.find(params[:role_id])
    @graph_data = build_graph_data(@tracker, @role)

    render partial: 'graph',
           locals:  { graph_data: @graph_data, tracker: @tracker, role: @role }
  end

  # GET /workflow_visualization/graph_data.json
  # AJAX용 JSON 데이터 엔드포인트
  def graph_data
    tracker = Tracker.find(params[:tracker_id])
    role    = Role.find(params[:role_id])

    render json: build_graph_data(tracker, role)
  rescue ActiveRecord::RecordNotFound => e
    render json: { error: e.message }, status: :not_found
  end

  private

  # -----------------------------------------------------------------------
  # WorkflowTransition 데이터를 그래프용 구조로 변환
  # -----------------------------------------------------------------------
  def build_graph_data(tracker, role)
    # Redmine 코어의 WorkflowTransition 모델 사용
    transitions = WorkflowTransition
                    .where(tracker_id: tracker.id, role_id: role.id)
                    .includes(:old_status, :new_status)

    # 해당 트래커가 사용하는 모든 상태
    status_ids = (transitions.map(&:old_status_id) +
                  transitions.map(&:new_status_id)).uniq.compact

    statuses = IssueStatus.where(id: status_ids).index_by(&:id)

    # 노드(상태) 목록
    nodes = statuses.values.map do |s|
      {
        id:        s.id,
        name:      s.name,
        is_closed: s.is_closed,
        color:     s.is_closed ? '#e8f5e9' : '#e3f2fd'
      }
    end

    # 엣지(전환) 목록
    edges = transitions.map do |t|
      next if t.old_status_id == 0 # 신규 이슈 생성 전환 제외 옵션

      {
        from:         t.old_status_id,
        to:           t.new_status_id,
        author_only:  t.author,
        assignee_only: t.assignee,
        from_name:    statuses[t.old_status_id]&.name || 'New',
        to_name:      statuses[t.new_status_id]&.name || 'Unknown'
      }
    end.compact

    # 신규 이슈 시작 상태 (old_status_id == 0)
    new_issue_transitions = transitions.select { |t| t.old_status_id == 0 }
    initial_status_ids    = new_issue_transitions.map(&:new_status_id).uniq

    {
      tracker:             { id: tracker.id, name: tracker.name },
      role:                { id: role.id, name: role.name },
      nodes:               nodes,
      edges:               edges,
      initial_status_ids:  initial_status_ids,
      default_status_id:   tracker.default_status_id
    }
  end
end