#!/bin/bash
# ═══════════════════════════════════════════════════════
# CupCash v3.0 — One-Click Deploy Script
# Run this on your VPS: bash deploy_cupcash.sh
# ═══════════════════════════════════════════════════════

set -e

echo ""
echo "🏆 CupCash v3.0 — Deploy Starting..."
echo "═══════════════════════════════════════════"

# 1. Install dependencies
echo "📦 Installing dependencies..."
pip3 install flask requests 2>/dev/null

# 2. Create project structure
echo "📁 Creating project structure..."
mkdir -p /root/cupcash/{static/{css,js,img},templates,data}
cd /root/cupcash

# 3. Kill old server
echo "🔄 Stopping old server..."
pkill -f "python3 server.py" 2>/dev/null || true
sleep 1

# 4. Create server.py
echo "⚙️  Creating server.py..."
cat > /root/cupcash/server.py << 'SERVEREOF'
#!/usr/bin/env python3
"""
⚽ CupCash v3.0 — WorldCup 2026 Predictor Telegram Mini App
$50K Reward Pool | Points System | 100pts per referral | Premium UI
Telegram Bot API compliant
"""
import os, json, time, uuid, datetime, requests
from pathlib import Path
from flask import Flask, jsonify, request, render_template

app = Flask(__name__, static_folder='static', template_folder='templates')
app.secret_key = 'cupcash-v3-worldcup-2026-professional'

DATA = Path(__file__).parent / 'data'
DATA.mkdir(exist_ok=True)
USERS_F = DATA / 'users.json'
PREDS_F = DATA / 'predictions.json'
MATCHES_F = DATA / 'matches.json'
REWARDS_F = DATA / 'rewards.json'

POOL_TOTAL = 50000.0
WC2026_API = 'https://api.wc2026api.com'

def load(f, default):
    try:
        with open(f) as fh: return json.load(fh)
    except: return default

def save(f, data):
    with open(f, 'w') as fh: json.dump(data, fh, indent=2, ensure_ascii=False)

def now(): return datetime.datetime.utcnow().isoformat()

def bd_time(utc_str):
    try:
        dt = datetime.datetime.fromisoformat(utc_str.replace('Z', '+00:00'))
        bd = dt + datetime.timedelta(hours=6)
        return bd.strftime('%H:%M')
    except: return utc_str

def bd_date(utc_str):
    try:
        dt = datetime.datetime.fromisoformat(utc_str.replace('Z', '+00:00'))
        bd = dt + datetime.timedelta(hours=6)
        return bd.strftime('%b %d')
    except: return ''

_cache = {'data': None, 'time': 0}

def fetch_matches():
    if time.time() - _cache['time'] < 60: return _cache['data']
    try:
        r = requests.get(f'{WC2026_API}/matches', timeout=10)
        if r.status_code == 200:
            _cache['data'] = r.json()
            _cache['time'] = time.time()
            save(MATCHES_F, _cache['data'])
            return _cache['data']
    except: pass
    return load(MATCHES_F, get_fallback())

def get_fallback():
    return [
        {"id":1,"match_number":1,"round":"group","group_name":"A","home_team":"Mexico","home_code":"MEX","away_team":"New Zealand","away_code":"NZL","stadium":"Estadio Azteca","kickoff_utc":"2026-06-11T16:00:00Z","status":"completed","home_score":2,"away_score":0},
        {"id":2,"match_number":2,"round":"group","group_name":"A","home_team":"Canada","home_code":"CAN","away_team":"Jamaica","away_code":"JAM","stadium":"BMO Field","kickoff_utc":"2026-06-12T16:00:00Z","status":"completed","home_score":1,"away_score":1},
        {"id":3,"match_number":3,"round":"group","group_name":"B","home_team":"USA","home_code":"USA","away_team":"Scotland","away_code":"SCO","stadium":"SoFi Stadium","kickoff_utc":"2026-06-13T21:00:00Z","status":"completed","home_score":3,"away_score":0},
        {"id":4,"match_number":4,"round":"group","group_name":"B","home_team":"Haiti","home_code":"HAI","away_team":"South Korea","away_code":"KOR","stadium":"Gillette Stadium","kickoff_utc":"2026-06-14T01:00:00Z","status":"completed","home_score":1,"away_score":2},
        {"id":5,"match_number":5,"round":"group","group_name":"C","home_team":"Brazil","home_code":"BRA","away_team":"Japan","away_code":"JPN","stadium":"MetLife Stadium","kickoff_utc":"2026-06-14T20:00:00Z","status":"live","home_score":1,"away_score":0},
        {"id":6,"match_number":6,"round":"group","group_name":"C","home_team":"Germany","home_code":"GER","away_team":"Netherlands","away_code":"NED","stadium":"AT&T Stadium","kickoff_utc":"2026-06-14T23:00:00Z","status":"scheduled","home_score":None,"away_score":None},
        {"id":7,"match_number":7,"round":"group","group_name":"D","home_team":"Argentina","home_code":"ARG","away_team":"Wales","away_code":"WAL","stadium":"Rose Bowl","kickoff_utc":"2026-06-15T02:00:00Z","status":"scheduled","home_score":None,"away_score":None},
        {"id":8,"match_number":8,"round":"group","group_name":"D","home_team":"France","home_code":"FRA","away_team":"Italy","away_code":"ITA","stadium":"Levi's Stadium","kickoff_utc":"2026-06-15T20:00:00Z","status":"scheduled","home_score":None,"away_score":None},
        {"id":9,"match_number":9,"round":"group","group_name":"E","home_team":"Spain","home_code":"ESP","away_team":"Portugal","away_code":"POR","stadium":"Hard Rock Stadium","kickoff_utc":"2026-06-15T23:00:00Z","status":"scheduled","home_score":None,"away_score":None},
        {"id":10,"match_number":10,"round":"group","group_name":"E","home_team":"England","home_code":"ENG","away_team":"Belgium","away_code":"BEL","stadium":"Mercedes-Benz Stadium","kickoff_utc":"2026-06-16T02:00:00Z","status":"scheduled","home_score":None,"away_score":None},
    ]

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/api/init', methods=['POST'])
def api_init():
    d = request.json or {}
    u = d.get('user', {})
    ref = d.get('referral', '')
    uid = str(u.get('id', ''))
    if not uid: return jsonify({'error':'No user'}), 400
    users = load(USERS_F, {})
    user = users.get(uid)
    if not user:
        user = {
            'id': uid, 'first_name': u.get('first_name',''),
            'last_name': u.get('last_name',''), 'username': u.get('username',''),
            'balance': 0.0, 'points': 0, 'total_earnings': 0.0,
            'predictions_correct': 0, 'predictions_total': 0,
            'referral_code': str(uuid.uuid4())[:8].upper(),
            'referred_by': ref if ref else '',
            'referrals': [], 'referral_points': 0, 'streak': 0,
            'joined_at': now(), 'last_active': now()
        }
        if ref and len(ref) == 8:
            for rid, ru in users.items():
                if ru.get('referral_code') == ref:
                    ru.setdefault('referrals', []).append(uid)
                    ru['points'] = ru.get('points', 0) + 100
                    ru['referral_points'] = ru.get('referral_points', 0) + 100
                    users[rid] = ru
                    break
        users[uid] = user
    else:
        user['last_active'] = now()
        users[uid] = user
    save(USERS_F, users)
    return jsonify({'user': user, 'success': True})

@app.route('/api/matches')
def api_matches():
    matches = fetch_matches() or get_fallback()
    enriched = []
    for m in matches:
        ut = m.get('kickoff_utc', '')
        mc = dict(m)
        mc['kickoff_bd'] = bd_time(ut)
        mc['kickoff_bd_date'] = bd_date(ut)
        mc['kickoff_utc_display'] = ut.replace('T',' ').replace('Z',' UTC') if ut else ''
        enriched.append(mc)
    order = {'live':0,'1H':0,'HT':0,'2H':0,'ET':0,'PEN':0,'scheduled':1,'completed':2,'FT':2,'FT_PEN':2}
    enriched.sort(key=lambda x: (order.get(x.get('status',''),1), x.get('match_number',999)))
    return jsonify({'matches': enriched, 'updated': now()})

@app.route('/api/predict', methods=['POST'])
def api_predict():
    d = request.json or {}
    uid = str(d.get('user_id',''))
    mid = d.get('match_id')
    ptype = d.get('type')
    pred = d.get('prediction')
    if not uid or mid is None or ptype not in ('winner','goals'):
        return jsonify({'error':'Invalid data'}), 400
    users = load(USERS_F, {})
    if uid not in users:
        return jsonify({'error':'User not found'}), 404
    mlist = fetch_matches() or get_fallback()
    match = next((m for m in mlist if m.get('id') == mid), None)
    if match and match.get('status') in ('completed','FT','FT_PEN','live','1H','2H','HT','ET','PEN'):
        return jsonify({'error':'Match already started/completed','status':match.get('status')}), 400
    preds = load(PREDS_F, {})
    mp = preds.get(str(mid), {})
    up = mp.get(uid, {})
    up[ptype] = {'prediction': pred, 'timestamp': now()}
    mp[uid] = up
    preds[str(mid)] = mp
    save(PREDS_F, preds)
    return jsonify({'success': True, 'prediction': up})

@app.route('/api/user/<uid>')
def api_user(uid):
    users = load(USERS_F, {})
    user = users.get(uid)
    if not user: return jsonify({'error':'Not found'}), 404
    all_preds = load(PREDS_F, {})
    user_preds = []
    for mid, mp in all_preds.items():
        if uid in mp:
            entry = {'match_id': mid}
            entry.update(mp[uid])
            user_preds.append(entry)
    rewards = load(REWARDS_F, {'distributed': 0})
    return jsonify({
        'user': user, 'predictions': user_preds,
        'reward_pool': {'total': POOL_TOTAL, 'remaining': POOL_TOTAL - rewards.get('distributed', 0), 'distributed': rewards.get('distributed', 0)}
    })

@app.route('/api/leaderboard')
def api_leaderboard():
    users = load(USERS_F, {})
    lb = sorted(
        [{'id':u['id'],'name':u.get('first_name',''),'username':u.get('username',''),'points':u.get('points',0),'balance':u.get('balance',0),'correct':u.get('predictions_correct',0),'total':u.get('predictions_total',0),'referrals':len(u.get('referrals',[])),'referral_points':u.get('referral_points',0)} for u in users.values()],
        key=lambda x: x['points'], reverse=True)[:100]
    return jsonify({'leaderboard': lb})

@app.route('/api/stats')
def api_stats():
    users = load(USERS_F, {})
    preds = load(PREDS_F, {})
    rewards = load(REWARDS_F, {'distributed': 0})
    return jsonify({'total_users': len(users),'total_predictions': sum(len(v) for v in preds.values()),'reward_pool': {'total': POOL_TOTAL,'remaining': POOL_TOTAL - rewards.get('distributed', 0),'distributed': rewards.get('distributed', 0)}})

@app.route('/api/score', methods=['POST'])
def api_score():
    d = request.json or {}
    mid = str(d.get('match_id',''))
    winner = d.get('winner')
    hg = d.get('home_goals', 0)
    ag = d.get('away_goals', 0)
    total = hg + ag
    preds = load(PREDS_F, {})
    mp = preds.get(mid, {})
    users = load(USERS_F, {})
    for uid, up in mp.items():
        if uid not in users: continue
        pts = 0
        if 'winner' in up and up['winner'].get('prediction') == winner: pts += 10
        if 'goals' in up:
            try:
                g = int(up['goals'].get('prediction', 0))
                if abs(g - total) <= 1: pts += 15
            except: pass
        if pts > 0:
            users[uid]['balance'] = users[uid].get('balance', 0) + pts
            users[uid]['points'] = users[uid].get('points', 0) + pts
            users[uid]['total_earnings'] = users[uid].get('total_earnings', 0) + pts
            users[uid]['predictions_correct'] = users[uid].get('predictions_correct', 0) + 1
        users[uid]['predictions_total'] = users[uid].get('predictions_total', 0) + 1
    save(USERS_F, users)
    rewards = load(REWARDS_F, {'distributed': 0, 'transactions': []})
    rewards['distributed'] = sum(u.get('balance', 0) for u in users.values())
    rewards['transactions'].append({'match_id': mid, 'time': now(), 'winner': winner, 'hg': hg, 'ag': ag})
    save(REWARDS_F, rewards)
    return jsonify({'success': True})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5500, debug=False)
SERVEREOF

chmod +x /root/cupcash/server.py

# 5. Create index.html (frontend)
echo "🎨 Creating frontend..."
cat > /root/cupcash/templates/index.html << 'HTMLEOF'
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no, viewport-fit=cover">
<meta name="theme-color" content="#070b14">
<title>CupCash 🏆 — World Cup 2026 Predictor</title>
<script src="https://telegram.org/js/telegram-web-app.js"></script>
<style>
:root{--c-bg:#070b14;--c-surface:#0d1320;--c-card:#111a2b;--c-card-2:#162033;--c-border:#1a2740;--c-border-light:#243650;--c-gold:#f5a623;--c-gold-glow:rgba(245,166,35,0.25);--c-green:#00e676;--c-red:#ff5252;--c-blue:#448aff;--c-purple:#b388ff;--c-cyan:#18ffff;--c-text:#e8edf5;--c-text-2:#8899b0;--c-text-3:#4a5f7a;--radius:16px;--radius-sm:10px;--radius-xs:6px;--shadow:0 8px 32px rgba(0,0,0,0.5);--shadow-gold:0 0 40px rgba(245,166,35,0.12);--transition:0.25s cubic-bezier(0.4,0,0.2,1)}
*{margin:0;padding:0;box-sizing:border-box;-webkit-tap-highlight-color:transparent}
html{scroll-behavior:smooth}
body{font-family:-apple-system,BlinkMacSystemFont,'SF Pro Display','Segoe UI',Roboto,sans-serif;background:var(--c-bg);color:var(--c-text);min-height:100vh;overflow-x:hidden;-webkit-font-smoothing:antialiased}
#loader{position:fixed;inset:0;z-index:10000;background:var(--c-bg);display:flex;flex-direction:column;align-items:center;justify-content:center;transition:opacity 0.6s,visibility 0.6s}
#loader.done{opacity:0;visibility:hidden}
.loader-ring{width:48px;height:48px;border:3px solid var(--c-border);border-top-color:var(--c-gold);border-radius:50%;animation:spin 0.8s linear infinite}
@keyframes spin{to{transform:rotate(360deg)}}
.loader-text{margin-top:14px;font-size:13px;font-weight:700;letter-spacing:3px;text-transform:uppercase;background:linear-gradient(90deg,var(--c-gold),var(--c-cyan));-webkit-background-clip:text;-webkit-text-fill-color:transparent}
.header{padding:16px 16px 0;position:sticky;top:0;z-index:50;background:linear-gradient(180deg,var(--c-bg) 80%,transparent)}
.header-top{display:flex;align-items:center;justify-content:space-between;margin-bottom:12px}
.logo{font-size:22px;font-weight:900;background:linear-gradient(135deg,var(--c-gold),#ff8f00);-webkit-background-clip:text;-webkit-text-fill-color:transparent;letter-spacing:-0.5px}
.header-actions{display:flex;gap:8px}
.icon-btn{width:36px;height:36px;border-radius:50%;border:1px solid var(--c-border);background:var(--c-surface);color:var(--c-text-2);display:flex;align-items:center;justify-content:center;font-size:16px;cursor:pointer;transition:all var(--transition)}
.icon-btn:hover{border-color:var(--c-gold);color:var(--c-gold)}
.pool-banner{margin:12px 16px;background:linear-gradient(135deg,#1a0a2e 0%,#0d1a3e 50%,#0a1628 100%);border:1px solid rgba(245,166,35,0.2);border-radius:var(--radius);padding:18px 16px;text-align:center;position:relative;overflow:hidden;box-shadow:var(--shadow-gold)}
.pool-banner::before{content:'';position:absolute;inset:0;background:radial-gradient(ellipse at 30% 20%,rgba(245,166,35,0.08) 0%,transparent 50%);pointer-events:none}
.pool-label{font-size:10px;font-weight:700;color:var(--c-gold);letter-spacing:2px;text-transform:uppercase;position:relative}
.pool-amount{font-size:32px;font-weight:900;color:var(--c-gold);margin:2px 0;text-shadow:0 0 40px rgba(245,166,35,0.3);position:relative;font-variant-numeric:tabular-nums}
.pool-sub{font-size:11px;color:var(--c-text-3);position:relative}
.pool-stats{display:flex;justify-content:center;gap:20px;margin-top:12px;padding-top:12px;border-top:1px solid rgba(245,166,35,0.1);position:relative}
.pool-stat{text-align:center}
.pool-stat-val{font-size:14px;font-weight:700;color:var(--c-text)}
.pool-stat-lbl{font-size:9px;color:var(--c-text-3);text-transform:uppercase;letter-spacing:1px}
.user-bar{display:flex;align-items:center;justify-content:space-between;margin:0 16px 12px;background:var(--c-surface);border:1px solid var(--c-border);border-radius:var(--radius-sm);padding:10px 12px}
.user-left{display:flex;align-items:center;gap:10px}
.avatar{width:34px;height:34px;border-radius:50%;background:linear-gradient(135deg,var(--c-gold),#ff8f00);display:flex;align-items:center;justify-content:center;font-size:14px;font-weight:800;color:#000;flex-shrink:0}
.user-name{font-size:13px;font-weight:600}
.user-sub{font-size:10px;color:var(--c-text-3)}
.balance-box{text-align:right}
.balance-lbl{font-size:9px;color:var(--c-text-3);text-transform:uppercase;letter-spacing:1px}
.balance-val{font-size:16px;font-weight:800;color:var(--c-green);font-variant-numeric:tabular-nums}
.nav-tabs{display:flex;margin:0 16px 12px;background:var(--c-surface);border:1px solid var(--c-border);border-radius:var(--radius-sm);padding:3px;gap:3px}
.nav-tab{flex:1;padding:8px 4px;text-align:center;border-radius:var(--radius-xs);font-size:11px;font-weight:600;color:var(--c-text-3);cursor:pointer;transition:all var(--transition);border:none;background:none;display:flex;flex-direction:column;align-items:center;gap:2px}
.nav-tab.active{background:linear-gradient(135deg,var(--c-gold),#ff8f00);color:#000;box-shadow:0 2px 12px rgba(245,166,35,0.3)}
.nav-tab-icon{font-size:16px}
.content{padding:0 16px 90px}
.tab-panel{display:none}
.tab-panel.active{display:block}
.section-title{font-size:13px;font-weight:700;color:var(--c-text-2);text-transform:uppercase;letter-spacing:1px;margin-bottom:10px;display:flex;align-items:center;gap:6px}
.match-card{background:var(--c-card);border:1px solid var(--c-border);border-radius:var(--radius);margin-bottom:10px;overflow:hidden;transition:all var(--transition);position:relative}
.match-card.live{border-color:var(--c-red);box-shadow:0 0 20px rgba(255,82,82,0.1)}
.match-card.completed{opacity:0.65}
.match-card.has-prediction{border-color:rgba(0,230,118,0.3)}
.match-card-top{display:flex;align-items:center;justify-content:space-between;padding:8px 12px;background:rgba(0,0,0,0.15);border-bottom:1px solid var(--c-border)}
.match-group{font-size:9px;color:var(--c-text-3);text-transform:uppercase;letter-spacing:1px;font-weight:600}
.match-badge{font-size:9px;font-weight:700;padding:2px 8px;border-radius:4px;text-transform:uppercase;letter-spacing:0.5px}
.badge-live{background:rgba(255,82,82,0.15);color:var(--c-red);animation:pulse 1.5s infinite}
.badge-scheduled{background:rgba(68,138,255,0.15);color:var(--c-blue)}
.badge-completed{background:rgba(0,230,118,0.15);color:var(--c-green)}
@keyframes pulse{0%,100%{opacity:1}50%{opacity:0.4}}
.match-body{padding:14px 12px}
.match-time{text-align:center;font-size:10px;color:var(--c-text-3);margin-bottom:10px;display:flex;justify-content:center;gap:12px}
.match-time-item{display:flex;align-items:center;gap:4px}
.match-time-item .tz{color:var(--c-gold);font-weight:600}
.match-teams{display:flex;align-items:center;justify-content:space-between}
.team{text-align:center;flex:1}
.team-emoji{font-size:28px;margin-bottom:2px;line-height:1}
.team-name{font-size:12px;font-weight:600;color:var(--c-text)}
.team-code{font-size:9px;color:var(--c-text-3)}
.match-center{padding:0 12px;text-align:center;min-width:70px}
.match-score{font-size:24px;font-weight:900;font-variant-numeric:tabular-nums}
.match-score .sep{color:var(--c-text-3);margin:0 2px}
.match-vs{font-size:12px;color:var(--c-text-3);font-weight:600}
.pred-area{padding:10px 12px;border-top:1px solid var(--c-border)}
.pred-label{font-size:9px;font-weight:700;color:var(--c-text-3);text-transform:uppercase;letter-spacing:1px;margin-bottom:8px}
.pred-row{display:flex;gap:6px;margin-bottom:8px}
.pred-btn{flex:1;padding:8px 4px;border:1px solid var(--c-border);border-radius:var(--radius-xs);background:rgba(255,255,255,0.02);color:var(--c-text-2);font-size:11px;font-weight:600;cursor:pointer;transition:all var(--transition);text-align:center;display:flex;flex-direction:column;align-items:center;gap:2px}
.pred-btn:hover{border-color:var(--c-gold);color:var(--c-gold)}
.pred-btn.sel{background:linear-gradient(135deg,var(--c-gold),#ff8f00);border-color:var(--c-gold);color:#000;box-shadow:0 2px 8px rgba(245,166,35,0.3)}
.pred-btn-emoji{font-size:16px}
.goals-row{display:flex;gap:6px;align-items:center}
.goals-input{flex:1;padding:8px;background:rgba(255,255,255,0.03);border:1px solid var(--c-border);border-radius:var(--radius-xs);color:var(--c-text);font-size:16px;font-weight:700;text-align:center;outline:none;transition:border-color var(--transition)}
.goals-input:focus{border-color:var(--c-gold)}
.goals-btn{padding:8px 16px;background:linear-gradient(135deg,var(--c-gold),#ff8f00);border:none;border-radius:var(--radius-xs);color:#000;font-size:12px;font-weight:700;cursor:pointer;transition:all var(--transition)}
.goals-btn:hover{transform:scale(1.05)}
.pred-done{text-align:center;padding:8px;background:rgba(0,230,118,0.08);border:1px solid rgba(0,230,118,0.2);border-radius:var(--radius-xs);color:var(--c-green);font-size:11px;font-weight:600}
.lb-item{display:flex;align-items:center;padding:10px 12px;background:var(--c-card);border:1px solid var(--c-border);border-radius:var(--radius-sm);margin-bottom:6px;transition:all var(--transition)}
.lb-item:hover{border-color:var(--c-border-light)}
.lb-rank{width:28px;height:28px;border-radius:50%;display:flex;align-items:center;justify-content:center;font-size:12px;font-weight:800;margin-right:10px;flex-shrink:0}
.rank-1{background:linear-gradient(135deg,#f5a623,#ff8f00);color:#000}
.rank-2{background:linear-gradient(135deg,#99aabe,#6b7f99);color:#000}
.rank-3{background:linear-gradient(135deg,#cd7f32,#a0522d);color:#fff}
.rank-other{background:var(--c-surface);color:var(--c-text-3);border:1px solid var(--c-border)}
.lb-info{flex:1;min-width:0}
.lb-name{font-size:13px;font-weight:600;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
.lb-sub{font-size:10px;color:var(--c-text-3)}
.lb-pts{font-size:14px;font-weight:800;color:var(--c-gold);font-variant-numeric:tabular-nums;flex-shrink:0}
.hist-item{display:flex;align-items:center;justify-content:space-between;padding:10px 12px;background:var(--c-card);border:1px solid var(--c-border);border-radius:var(--radius-sm);margin-bottom:6px}
.hist-match{font-size:12px;font-weight:600}
.hist-pred{font-size:11px;color:var(--c-text-2)}
.hist-status{font-size:11px;font-weight:700;color:var(--c-text-3)}
.profile-hero{background:linear-gradient(135deg,#1a0a2e,#0d1a3e);border:1px solid rgba(245,166,35,0.15);border-radius:var(--radius);padding:24px 16px;text-align:center;margin-bottom:12px}
.profile-avatar{width:60px;height:60px;border-radius:50%;background:linear-gradient(135deg,var(--c-gold),#ff8f00);display:inline-flex;align-items:center;justify-content:center;font-size:24px;font-weight:900;color:#000;margin-bottom:10px;box-shadow:0 0 30px rgba(245,166,35,0.2)}
.profile-name{font-size:17px;font-weight:700}
.profile-uname{font-size:12px;color:var(--c-text-3);margin-bottom:14px}
.profile-grid{display:grid;grid-template-columns:repeat(3,1fr);gap:8px}
.pstat{background:rgba(0,0,0,0.2);border-radius:var(--radius-xs);padding:10px 6px}
.pstat-val{font-size:18px;font-weight:800;color:var(--c-gold);font-variant-numeric:tabular-nums}
.pstat-lbl{font-size:9px;color:var(--c-text-3);text-transform:uppercase;letter-spacing:0.5px;margin-top:2px}
.ref-box{background:linear-gradient(135deg,#1a0a2e,#0d1020);border:1px solid rgba(179,136,255,0.2);border-radius:var(--radius);padding:16px;margin-bottom:12px}
.ref-title{font-size:13px;font-weight:700;color:var(--c-purple);margin-bottom:8px}
.ref-code{background:rgba(0,0,0,0.3);border:1px dashed var(--c-purple);border-radius:var(--radius-xs);padding:10px;text-align:center;font-size:20px;font-weight:900;letter-spacing:4px;color:var(--c-purple);margin-bottom:6px;cursor:pointer;user-select:all}
.ref-sub{font-size:10px;color:var(--c-text-3);text-align:center}
.toast{position:fixed;bottom:84px;left:50%;transform:translateX(-50%) translateY(80px);background:var(--c-surface);border:1px solid var(--c-border);border-radius:var(--radius-sm);padding:10px 18px;font-size:12px;font-weight:600;color:var(--c-text);z-index:200;transition:transform 0.3s cubic-bezier(0.4,0,0.2,1);box-shadow:var(--shadow);white-space:nowrap;max-width:90vw}
.toast.show{transform:translateX(-50%) translateY(0)}
.toast.ok{border-color:var(--c-green);color:var(--c-green)}
.toast.err{border-color:var(--c-red);color:var(--c-red)}
.skeleton{background:linear-gradient(90deg,var(--c-card) 25%,var(--c-card-2) 50%,var(--c-card) 75%);background-size:200% 100%;animation:shimmer 1.5s infinite;border-radius:var(--radius-xs)}
@keyframes shimmer{0%{background-position:200% 0}100%{background-position:-200% 0}}
.confetti-piece{position:fixed;width:8px;height:8px;border-radius:2px;z-index:300;pointer-events:none;animation:confetti-fall 2s ease-out forwards}
@keyframes confetti-fall{0%{transform:translateY(-10vh) rotate(0deg);opacity:1}100%{transform:translateY(100vh) rotate(720deg);opacity:0}}
.fade-up{animation:fadeUp 0.4s ease-out both}
@keyframes fadeUp{from{opacity:0;transform:translateY(12px)}to{opacity:1;transform:translateY(0)}}
.empty{text-align:center;padding:30px 16px;color:var(--c-text-3)}
.empty-icon{font-size:32px;margin-bottom:8px}
.empty-text{font-size:12px}
::-webkit-scrollbar{width:3px}
::-webkit-scrollbar-track{background:transparent}
::-webkit-scrollbar-thumb{background:var(--c-border);border-radius:3px}
</style>
</head>
<body>
<div id="loader"><div class="loader-ring"></div><div class="loader-text">CupCash</div></div>
<div id="toast" class="toast"></div>
<div class="header">
  <div class="header-top">
    <div class="logo">🏆 CupCash</div>
    <div class="header-actions">
      <button class="icon-btn" onclick="showStreak()" title="Streak">🔥</button>
      <button class="icon-btn" onclick="refreshAll()" title="Refresh">🔄</button>
    </div>
  </div>
  <div class="pool-banner">
    <div class="pool-label">🎯 Total Reward Pool</div>
    <div class="pool-amount" id="pool-amount">$50,000</div>
    <div class="pool-sub">Predict daily & earn your share!</div>
    <div class="pool-stats">
      <div class="pool-stat"><div class="pool-stat-val" id="stat-users">0</div><div class="pool-stat-lbl">Players</div></div>
      <div class="pool-stat"><div class="pool-stat-val" id="stat-preds">0</div><div class="pool-stat-lbl">Predictions</div></div>
      <div class="pool-stat"><div class="pool-stat-val" id="stat-pts">0</div><div class="pool-stat-lbl">Points Given</div></div>
    </div>
  </div>
  <div class="user-bar" id="user-bar">
    <div class="user-left">
      <div class="avatar" id="u-avatar">?</div>
      <div><div class="user-name" id="u-name">Player</div><div class="user-sub" id="u-uname">@username</div></div>
    </div>
    <div class="balance-box">
      <div class="balance-lbl">Points</div>
      <div class="balance-val" id="u-pts">0</div>
    </div>
  </div>
  <div class="nav-tabs">
    <button class="nav-tab active" data-tab="matches" onclick="goTab('matches')"><span class="nav-tab-icon">⚽</span>Matches</button>
    <button class="nav-tab" data-tab="history" onclick="goTab('history')"><span class="nav-tab-icon">📋</span>History</button>
    <button class="nav-tab" data-tab="leaderboard" onclick="goTab('leaderboard')"><span class="nav-tab-icon">🏆</span>Top</button>
    <button class="nav-tab" data-tab="profile" onclick="goTab('profile')"><span class="nav-tab-icon">👤</span>Profile</button>
  </div>
</div>
<div class="content">
  <div class="tab-panel active" id="tab-matches">
    <div class="section-title">📅 Upcoming & Live</div>
    <div id="matches-list"><div class="skeleton" style="height:120px;margin-bottom:10px"></div><div class="skeleton" style="height:120px;margin-bottom:10px"></div><div class="skeleton" style="height:120px"></div></div>
  </div>
  <div class="tab-panel" id="tab-history">
    <div class="section-title">📋 Your Predictions</div>
    <div id="history-list"><div class="empty"><div class="empty-icon">📋</div><div class="empty-text">No predictions yet</div></div></div>
  </div>
  <div class="tab-panel" id="tab-leaderboard">
    <div class="section-title">🏆 Top Predictors</div>
    <div id="lb-list"><div class="skeleton" style="height:52px;margin-bottom:6px"></div><div class="skeleton" style="height:52px;margin-bottom:6px"></div><div class="skeleton" style="height:52px"></div></div>
  </div>
  <div class="tab-panel" id="tab-profile">
    <div id="profile-content"></div>
  </div>
</div>
<script>
const S={user:null,matches:[],preds:{},allUserPreds:[],streak:0,tg:null};
try{if(window.Telegram?.WebApp){S.tg=window.Telegram.WebApp;S.tg.ready();S.tg.expand();S.tg.setHeaderColor('#070b14');S.tg.setBackgroundColor('#070b14')}}catch(e){}
async function init(){
  try{
    let ud=null;
    if(S.tg?.initDataUnsafe?.user){ud=S.tg.initDataUnsafe.user}else{ud={id:123456,first_name:'Player',username:'player_dev'}}
    const ref=S.tg?.initDataUnsafe?.start_param||new URLSearchParams(location.search).get('ref')||'';
    const res=await post('/api/init',{user:ud,referral:ref,initData:S.tg?.initData||''});
    if(res.user){S.user=res.user;updateUserUI()}
    await Promise.all([loadMatches(),loadLeaderboard(),loadStats(),loadUserPreds()]);
    setTimeout(()=>{document.getElementById('loader').classList.add('done')},300)
  }catch(e){console.error(e);toast('Connection error','err')}
}
async function post(url,body){const r=await fetch(url,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(body)});return r.json()}
async function get(url){const r=await fetch(url);return r.json()}
function updateUserUI(){
  if(!S.user)return;
  document.getElementById('u-name').textContent=S.user.first_name||'Player';
  document.getElementById('u-uname').textContent='@'+(S.user.username||'no_username');
  document.getElementById('u-pts').textContent=(S.user.points||0).toLocaleString();
  document.getElementById('u-avatar').textContent=(S.user.first_name||'?')[0].toUpperCase()
}
async function loadMatches(){try{const d=await get('/api/matches');S.matches=d.matches||[];renderMatches()}catch(e){console.error(e)}}
function renderMatches(){
  const el=document.getElementById('matches-list');
  if(!S.matches.length){el.innerHTML='<div class="empty"><div class="empty-icon">⚽</div><div class="empty-text">No matches</div></div>';return}
  el.innerHTML=S.matches.map((m,i)=>{
    const isLive=['live','1H','2H','HT','ET','PEN'].includes(m.status);
    const isDone=['completed','FT','FT_PEN'].includes(m.status);
    const canPredict=!isLive&&!isDone;
    const myPred=S.preds[m.id]||{};
    const hasW=!!myPred.winner;
    const hasG=!!myPred.goals;
    const hasAny=hasW||hasG;
    const bc=isLive?'badge-live':(isDone?'badge-completed':'badge-scheduled');
    const bt=isLive?'● LIVE':(isDone?'FT':'UPCOMING');
    const cc='match-card fade-up'+(isLive?' live':'')+(isDone?' completed':'')+(hasAny?' has-prediction':'');
    const scoreHTML=(m.home_score!=null&&m.away_score!=null)?'<div class="match-center"><div class="match-score">'+m.home_score+'<span class="sep">-</span>'+m.away_score+'</div></div>':'<div class="match-center"><div class="match-vs">VS</div></div>';
    let predHTML='';
    if(canPredict){
      if(hasAny){
        const parts=[];if(hasW){const w=myPred.winner.prediction;parts.push('🏆 '+(w==='home'?m.home_code:(w==='away'?m.away_code:'Draw')))}if(hasG)parts.push('⚽ '+myPred.goals.prediction+' goals');
        predHTML='<div class="pred-area"><div class="pred-done">✅ '+parts.join(' • ')+'</div></div>'
      }else{
        predHTML='<div class="pred-area"><div class="pred-label">🏆 Winner</div><div class="pred-row"><button class="pred-btn" onclick="pickWinner('+m.id+',\'home\')"><span class="pred-btn-emoji">🏠</span>'+(m.home_code||'H')+'</button><button class="pred-btn" onclick="pickWinner('+m.id+',\'draw\')"><span class="pred-btn-emoji">🤝</span>Draw</button><button class="pred-btn" onclick="pickWinner('+m.id+',\'away\')"><span class="pred-btn-emoji">✈️</span>'+(m.away_code||'A')+'</button></div><div class="pred-label" style="margin-top:6px">⚽ Total Goals</div><div class="goals-row"><input type="number" class="goals-input" id="g-'+m.id+'" min="0" max="20" placeholder="0"><button class="goals-btn" onclick="pickGoals('+m.id+')">Save</button></div></div>'
      }
    }else if(hasAny){
      const parts=[];if(hasW){const w=myPred.winner.prediction;parts.push('🏆 '+(w==='home'?m.home_code:(w==='away'?m.away_code:'Draw')))}if(hasG)parts.push('⚽ '+myPred.goals.prediction);
      predHTML='<div class="pred-area"><div class="pred-done">📌 Your pick: '+parts.join(' • ')+'</div></div>'
    }
    return '<div class="'+cc+'" style="animation-delay:'+(i*0.05)+'s"><div class="match-card-top"><span class="match-group">Group '+(m.group_name||'•')+' • '+(m.stadium||'')+'</span><span class="match-badge '+bc+'">'+bt+'</span></div><div class="match-body"><div class="match-time"><span class="match-time-item">🇧🇩 <span class="tz">'+(m.kickoff_bd||'--:--')+'</span></span><span class="match-time-item">🌍 <span>'+(m.kickoff_utc_display||'')+'</span></span></div><div class="match-teams"><div class="team"><div class="team-emoji">'+flag(m.home_code)+'</div><div class="team-name">'+m.home_team+'</div><div class="team-code">'+(m.home_code||'')+'</div></div>'+scoreHTML+'<div class="team"><div class="team-emoji">'+flag(m.away_code)+'</div><div class="team-name">'+m.away_team+'</div><div class="team-code">'+(m.away_code||'')+'</div></div></div></div>'+predHTML+'</div>'
  }).join('')
}
function flag(c){const f={'MEX':'🇲🇽','NZL':'🇳🇿','CAN':'🇨🇦','JAM':'🇯🇲','USA':'🇺🇸','SCO':'🏴󠁧󠁢󠁳󠁣󠁴󠁿','HAI':'🇭🇹','KOR':'🇰🇷','BRA':'🇧🇷','JPN':'🇯🇵','GER':'🇩🇪','NED':'🇳🇱','ARG':'🇦🇷','WAL':'🏴󠁧󠁢󠁷󠁬󠁳󠁿','FRA':'🇫🇷','ITA':'🇮🇹','ENG':'🏴󠁧󠁢󠁥󠁮󠁧󠁿','ESP':'🇪🇸','POR':'🇵🇹','BEL':'🇧🇪','CRO':'🇭🇷','URU':'🇺🇾','COL':'🇨🇴','SEN':'🇸🇳','MAR':'🇲🇦','IRN':'🇮🇷','AUS':'🇦🇺','POL':'🇵🇱','SUI':'🇨🇭','DEN':'🇩🇰','SRB':'🇷🇸','CMR':'🇨🇲','GHA':'🇬🇭','KSA':'🇸🇦','TUN':'🇹🇳','ECU':'🇪🇨','QAT':'🇶🇦','CRC':'🇨🇷','UKR':'🇺🇦','TUR':'🇹🇷','NOR':'🇳🇴','SWE':'🇸🇪'};return f[c]||'🏳️'}
async function pickWinner(mid,val){
  if(!S.user)return;
  try{const r=await post('/api/predict',{user_id:S.user.id,match_id:mid,type:'winner',prediction:val});if(r.success){if(!S.preds[mid])S.preds[mid]={};S.preds[mid].winner={prediction:val};renderMatches();toast('✅ Winner saved!','ok')}else toast(r.error||'Failed','err')}catch(e){toast('Error','err')}
}
async function pickGoals(mid){
  if(!S.user)return;
  const el=document.getElementById('g-'+mid);const val=parseInt(el?.value);
  if(isNaN(val)){toast('Enter a number','err');return}
  try{const r=await post('/api/predict',{user_id:S.user.id,match_id:mid,type:'goals',prediction:val});if(r.success){if(!S.preds[mid])S.preds[mid]={};S.preds[mid].goals={prediction:val};renderMatches();toast('✅ Goals saved!','ok')}else toast(r.error||'Failed','err')}catch(e){toast('Error','err')}
}
async function loadUserPreds(){
  if(!S.user)return;
  try{const d=await get('/api/user/'+S.user.id);if(d.predictions){S.allUserPreds=d.predictions;d.predictions.forEach(p=>{if(!S.preds[p.match_id])S.preds[p.match_id]={};if(p.winner)S.preds[p.match_id].winner=p.winner;if(p.goals)S.preds[p.match_id].goals=p.goals});renderMatches();renderHistory()}if(d.user){S.user=d.user;updateUserUI()}}catch(e){console.error(e)}
}
function renderHistory(){
  const el=document.getElementById('history-list');
  if(!S.allUserPreds.length){el.innerHTML='<div class="empty"><div class="empty-icon">📋</div><div class="empty-text">No predictions yet</div></div>';return}
  el.innerHTML=S.allUserPreds.map((p,i)=>{
    const m=S.matches.find(x=>x.id==p.match_id);
    const mn=m?m.home_team+' vs '+m.away_team:'Match #'+p.match_id;
    const parts=[];if(p.winner){const w=p.winner.prediction;parts.push('Winner: '+(w==='home'?'Home':(w==='away'?'Away':'Draw')))}if(p.goals)parts.push('Goals: '+p.goals.prediction);
    return '<div class="hist-item fade-up" style="animation-delay:'+(i*0.05)+'s"><div><div class="hist-match">'+mn+'</div><div class="hist-pred">'+(parts.join(' • ')||'No details')+'</div></div><div class="hist-status">⏳ Pending</div></div>'
  }).join('')
}
async function loadLeaderboard(){try{const d=await get('/api/leaderboard');renderLB(d.leaderboard||[])}catch(e){console.error(e)}}
function renderLB(list){
  const el=document.getElementById('lb-list');
  if(!list.length){el.innerHTML='<div class="empty"><div class="empty-icon">🏆</div><div class="empty-text">Be the first!</div></div>';return}
  el.innerHTML=list.map((p,i)=>{
    const rc=i===0?'rank-1':(i===1?'rank-2':(i===2?'rank-3':'rank-other'));
    return '<div class="lb-item fade-up" style="animation-delay:'+(i*0.04)+'s"><div class="lb-rank '+rc+'">'+(i+1)+'</div><div class="lb-info"><div class="lb-name">'+(p.name||'Player')+'</div><div class="lb-sub">'+(p.correct||0)+'/'+(p.total||0)+' correct • '+(p.referrals||0)+' refs</div></div><div class="lb-pts">'+(p.points||0).toLocaleString()+' pts</div></div>'
  }).join('')
}
async function loadStats(){try{const d=await get('/api/stats');document.getElementById('stat-users').textContent=d.total_users||0;document.getElementById('stat-preds').textContent=d.total_predictions||0;document.getElementById('stat-pts').textContent=(d.reward_pool?.distributed||0).toLocaleString()}catch(e){}}
function renderProfile(){
  if(!S.user)return;
  document.getElementById('profile-content').innerHTML='<div class="profile-hero fade-up"><div class="profile-avatar">'+((S.user.first_name||'?')[0].toUpperCase())+'</div><div class="profile-name">'+(S.user.first_name||'Player')+' '+(S.user.last_name||'')+'</div><div class="profile-uname">@'+(S.user.username||'no_username')+'</div><div class="profile-grid"><div class="pstat"><div class="pstat-val">'+(S.user.points||0).toLocaleString()+'</div><div class="pstat-lbl">Points</div></div><div class="pstat"><div class="pstat-val">'+(S.user.predictions_correct||0)+'</div><div class="pstat-lbl">Correct</div></div><div class="pstat"><div class="pstat-val">'+(S.user.referral_points||0)+'</div><div class="pstat-lbl">Ref Points</div></div></div></div><div class="ref-box fade-up"><div class="ref-title">🎁 Referral Code (100 pts each!)</div><div class="ref-code" onclick="copyRef()">'+(S.user.referral_code||'N/A')+'</div><div class="ref-sub">Tap to copy • 100 points per friend!</div></div>'
}
function copyRef(){
  if(!S.user?.referral_code)return;
  const link='https://t.me/CupCash_Bot?startapp='+S.user.referral_code;
  try{navigator.clipboard.writeText(link)}catch(e){}
  toast('✅ Link copied!','ok')
}
function showStreak(){toast('🔥 Streak feature coming soon!','ok')}
function goTab(name){
  document.querySelectorAll('.nav-tab').forEach(t=>t.classList.toggle('active',t.dataset.tab===name));
  document.querySelectorAll('.tab-panel').forEach(p=>p.classList.toggle('active',p.id==='tab-'+name));
  if(name==='profile')renderProfile();if(name==='history')renderHistory();if(name==='leaderboard')loadLeaderboard()
}
async function refreshAll(){await Promise.all([loadMatches(),loadLeaderboard(),loadStats(),loadUserPreds()]);toast('✅ Refreshed!','ok')}
function toast(msg,type){const el=document.getElementById('toast');el.textContent=msg;el.className='toast '+(type||'')+' show';setTimeout(()=>el.className='toast',2500)}
function confetti(){const c=['#f5a623','#00e676','#448aff','#b388ff','#ff5252','#18ffff'];for(let i=0;i<40;i++){const d=document.createElement('div');d.className='confetti-piece';d.style.left=Math.random()*100+'vw';d.style.background=c[Math.floor(Math.random()*c.length)];d.style.animationDelay=Math.random()*0.5+'s';d.style.borderRadius=Math.random()>0.5?'50%':'2px';document.body.appendChild(d);setTimeout(()=>d.remove(),2500)}}
function animatePool(){const el=document.getElementById('pool-amount');const t=50000;let cur=0;const s=t/60;const iv=setInterval(()=>{cur+=s;if(cur>=t){cur=t;clearInterval(iv)}el.textContent='$'+Math.floor(cur).toLocaleString()},16)}
init();animatePool();setInterval(loadMatches,30000);
</script>
</body>
</html>
HTMLEOF

# 6. Start server
echo "🚀 Starting server..."
nohup python3 server.py > /tmp/cupcash.log 2>&1 &
sleep 3

# 7. Test
echo ""
echo "═══════════════════════════════════════════"
echo "✅ CupCash v3.0 Deployed!"
echo "═══════════════════════════════════════════"
echo ""
echo "🌐 App:       http://$(curl -s ifconfig.me 2>/dev/null || echo 'localhost'):5500/"
echo "📊 API Stats: http://$(curl -s ifconfig.me 2>/dev/null || echo 'localhost'):5500/api/stats"
echo "⚽ Matches:   http://$(curl -s ifconfig.me 2>/dev/null || echo 'localhost'):5500/api/matches"
echo ""
echo "📝 Referral: 100 points per friend"
echo "🏆 Leaderboard: Sorted by points"
echo "═══════════════════════════════════════════"
