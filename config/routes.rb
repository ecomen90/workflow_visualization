# plugins/workflow_visualization/config/routes.rb

get  'workflow_visualization',
     to: 'workflow_visualizations#index',
     as: 'workflow_visualization'

get  'workflow_visualization/show',
     to: 'workflow_visualizations#show',
     as: 'workflow_visualization_show'

get  'workflow_visualization/graph_data',
     to: 'workflow_visualizations#graph_data',
     as: 'workflow_visualization_graph_data'