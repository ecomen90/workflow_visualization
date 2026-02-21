# plugins/workflow_visualization/app/helpers/workflow_visualizations_helper.rb

module WorkflowVisualizationsHelper

  def build_mermaid_definition(graph_data)
    lines = ["stateDiagram-v2"]
    lines << "    direction LR"
    lines << ""

    nodes          = graph_data[:nodes]          || []
    edges          = graph_data[:edges]          || []
    initial_ids    = graph_data[:initial_status_ids] || []
    closed_ids     = nodes.select { |n| n[:is_closed] }.map { |n| n[:id] }

    # ── 노드 별칭 정의 ───────────────────────────────────────────
    # ★ 이름에 한글, 공백, 특수문자가 있어도 안전하게 처리
    nodes.each do |node|
      safe_id   = "s#{node[:id]}"
      # Mermaid 노드 이름에서 콜론(:)과 줄바꿈 제거
      safe_name = node[:name]
                    .to_s
                    .gsub(/[:\n\r"#]/, "")
                    .strip
      lines << "    #{safe_id} : #{safe_name}"
    end

    lines << ""

    # ── 초기 상태 → [*] ──────────────────────────────────────────
    initial_ids.each do |sid|
      lines << "    [*] --> s#{sid}"
    end

    lines << ""

    # ── 전환 엣지 ────────────────────────────────────────────────
    # ★ 엣지 레이블에 한글 사용 시 Mermaid 파서 오류 방지
    #   → 레이블을 영문 약어로 변환
    edges.each do |edge|
      from_id = "s#{edge[:from]}"
      to_id   = "s#{edge[:to]}"

      # ★ 레이블을 한글 대신 이모지+약어로 변경 (파싱 안정성 향상)
      label = if edge[:author_only] && edge[:assignee_only]
                " : Author+Assignee"
              elsif edge[:author_only]
                " : Author only"
              elsif edge[:assignee_only]
                " : Assignee only"
              else
                ""   # 레이블 없음 (모든 사용자)
              end

      lines << "    #{from_id} --> #{to_id}#{label}"
    end

    lines << ""

    # ── 종료 상태 → [*] ──────────────────────────────────────────
    closed_ids.each do |sid|
      lines << "    s#{sid} --> [*]"
    end

    lines.join("\n")
  end

  # ★ 뷰에서 data 속성으로 원본 정의를 HTML에 삽입하는 헬퍼
  #   JavaScript가 DOM 처리 전에 안전하게 읽을 수 있도록 지원
  def mermaid_div_tag(graph_data)
    definition = build_mermaid_definition(graph_data)
    content_tag(
      :div,
      definition,                          # div 내부 텍스트 = Mermaid 정의
      class:              "mermaid",
      id:                 "wv-diagram",
      "data-mermaid-src": definition       # ★ data 속성에도 동일 저장
    )
  end
end
