#!/usr/bin/env python3
"""
⚽ CupCash v2.0 — WorldCup 2026 Predictor Telegram Mini App
$50K Reward Pool | Daily Predictions | Premium UI
Professional-grade backend with all bugs fixed
"""
import os, json, time, uuid, datetime, requests
from pathlib import Path
from flask import Flask, jsonify, request, render_template

app = Flask(__name__, static_folder='static', template_folder='templates')
app.secret_key = 'cupcash-v2-worldcup-2026-professional'

# ── PATHS ──
DATA = Path(__file__).parent / 'data'
DATA.mkdir(exist_ok=True)
USERS_F = DATA / 'users.json'
PREDS_F = DATA / 'predictions.json'
MATCHES_F = DATA / 'matches.json'
REWARDS_F = DATA / 'rewards.json'

# ── CONFIG ──
POOL_TOTAL = 50000.0
WC2026_API = 'https://api.wc2026api.com'

# ── HELPERS ──
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

# ── ROUTES ──
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
        # Referral bonus — 100 points per referral
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

    # Check match status
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
        'reward_pool': {
            'total': POOL_TOTAL,
            'remaining': POOL_TOTAL - rewards.get('distributed', 0),
            'distributed': rewards.get('distributed', 0)
        }
    })

@app.route('/api/leaderboard')
def api_leaderboard():
    users = load(USERS_F, {})
    lb = sorted(
        [{'id':u['id'],'name':u.get('first_name',''),'username':u.get('username',''),
          'points':u.get('points',0),'balance':u.get('balance',0),'correct':u.get('predictions_correct',0),
          'total':u.get('predictions_total',0),'referrals':len(u.get('referrals',[])),
          'referral_points':u.get('referral_points',0)}
         for u in users.values()],
        key=lambda x: x['points'], reverse=True
    )[:100]
    return jsonify({'leaderboard': lb})

@app.route('/api/stats')
def api_stats():
    users = load(USERS_F, {})
    preds = load(PREDS_F, {})
    rewards = load(REWARDS_F, {'distributed': 0})
    return jsonify({
        'total_users': len(users),
        'total_predictions': sum(len(v) for v in preds.values()),
        'reward_pool': {
            'total': POOL_TOTAL,
            'remaining': POOL_TOTAL - rewards.get('distributed', 0),
            'distributed': rewards.get('distributed', 0)
        }
    })

@app.route('/api/score', methods=['POST'])
def api_score():
    """Admin: Score a completed match"""
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
        if 'winner' in up and up['winner'].get('prediction') == winner:
            pts += 10
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
