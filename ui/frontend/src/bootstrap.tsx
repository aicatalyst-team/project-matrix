import React from 'react';
import ReactDOM from 'react-dom/client';
import { BrowserRouter as Router } from 'react-router-dom';
import ProjectMatrixPage from './app/pages/ProjectMatrixPage';

const root = ReactDOM.createRoot(document.getElementById('root')!);

root.render(
  <React.StrictMode>
    <Router>
      <ProjectMatrixPage />
    </Router>
  </React.StrictMode>,
);

