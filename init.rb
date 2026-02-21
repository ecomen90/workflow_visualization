# plugins/workflow_visualization/init.rb

Redmine::Plugin.register :workflow_visualization do
  name        'Workflow Visualization'
  author      'BYUNGJONG MOOON'
  description 'Visualizes Redmine workflow transitions as interactive diagrams'
  version     '1.0.0'
  url         'https://github.com/ecomen90/workflow_visualization'

  requires_redmine version_or_higher: '5.0'

  # 관리자 메뉴에 추가
  menu :admin_menu,
       :workflow_visualization,
       { controller: 'workflow_visualizations', action: 'index' },
       caption:  :label_workflow_visualization,
       html:     { class: 'icon' },
       after:    :workflows

  # 권한 선언
  permission :view_workflow_visualization,
             { workflow_visualizations: [:index, :show, :graph_data] },
             public: false,
             require: :loggedin
end
