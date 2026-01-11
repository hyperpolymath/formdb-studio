// SPDX-License-Identifier: AGPL-3.0-or-later
// FormDB Studio - Entry point

import React from 'react';
import ReactDOM from 'react-dom/client';
import { make as App } from './App.res.js';

const root = ReactDOM.createRoot(document.getElementById('root')!);
root.render(React.createElement(App, {}));
