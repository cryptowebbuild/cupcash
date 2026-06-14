#!/usr/bin/env python3
"""
⚽ CupCash v3.0 — WorldCup 2026 Predictor Telegram Mini App
$50K Reward Pool | Real WC2026 Data | Premium UI
"""
import os, json, time, uuid, datetime, requests
from pathlib import Path
from flask import Flask, jsonify, request, render_template, send_from_directory
from flask_cors import CORS

app = Flask(__name__, static_folder='static', template_folder='templates')
CORS(app)
app.secret_key = 'cupcash-v3-worldcup-2026'

# ── PATHS ──
DATA = Path(__file__).parent / 'data'
DATA.mkdir(exist_ok=True)
USERS_F = DATA / 'users.json'
PREDS_F = DATA / 'predictions.json'
MATCHES_F = DATA / 'matches.json'
REWARDS_F = DATA / 'rewards.json'

# ── CONFIG ──
POOL_TOTAL = 50000.0

# ── REAL WORLD CUP 2024 DATA ──
REAL_MATCHES = [
    # Group A
    {"id":1,"match_number":1,"round":"group","group_name":"A","home_team":"Mexico","home_code":"MEX","away_team":"South Africa","away_code":"RSA","stadium":"Estadio Azteca, Mexico City","kickoff_utc":"2026-06-11T21:00:00Z","status":"completed","home_score":2,"away_score":0},
    {"id":2,"match_number":2,"round":"group","group_name":"A","home_team":"South Korea","home_code":"KOR","away_team":"Czechia","away_code":"CZE","stadium":"Estadio Akron, Guadalajara","kickoff_utc":"2026-06-12T04:00:00Z","status":"completed","home_score":2,"away_score":1},
    {"id":17,"match_number":17,"round":"group","group_name":"A","home_team":"Czechia","home_code":"CZE","away_team":"South Africa","away_code":"RSA","stadium":"Atlanta Stadium, Atlanta","kickoff_utc":"2026-06-18T17:00:00Z","status":"scheduled","home_score":None,"away_score":None},
    {"id":18,"match_number":18,"round":"group","group_name":"A","home_team":"Mexico","home_code":"MEX","away_team":"South Korea","home_code":"KOR","stadium":"Estadio Akron, Guadalajara","kickoff_utc":"2026-06-18T23:00:00Z","status":"scheduled","home_score":None,"away_score":None},
    {"id":33,"match_number":33,"round":"group","group_name":"A","home_team":"Czechia","home_code":"CZE","away_team":"Mexico","home_code":"MEX","stadium":"Estadio Azteca, Mexico City","kickoff_utc":"2026-06-24T23:00:00Z","status":"scheduled","home_score":None,"away_score":None},
    {"id":34,"match_number":34,"round":"group","group_name":"A","home_team":"South Africa","away_code":"RSA","away_team":"South Korea","home_code":"KOR","stadium":"Estadio Monterrey, Monterrey","kickoff_utc":"2026-06-24T23:00:00Z","status":"scheduled","home_score":None,"away_score":None},
    # Group B
    {"id":3,"match_number":3,"round":"group","group_name":"B","home_team":"Canada","home_code":"CAN","away_team":"Bosnia & Herzegovina","away_code":"BIH","stadium":"BMO Field, Toronto","kickoff_utc":"2026-06-12T20:00:00Z","status":"completed","home_score":1,"away_score":1},
    {"id":4,"match_number":4,"round":"group","group_name":"B","home_team":"Qatar","home_code":"QAT","away_team":"Switzerland","away_code":"SUI","stadium":"Levi's Stadium, Santa Clara","kickoff_utc":"2026-06-13T19:00:00Z","status":"completed","home_score":1,"away_score":1},
    {"id":19,"match_number":19,"round":"group","group_name":"B","home_team":"Switzerland","away_code":"SUI","away_team":"Bosnia & Herzegovina","home_code":"BIH","stadium":"SoFi Stadium, Los Angeles","kickoff_utc":"2026-06-18T19:00:00Z","status":"scheduled","home_score":None,"away_score":None},
    {"id":20,"match_number":20,"round":"group","group_name":"B","home_team":"Canada","home_code":"CAN","away_team":"Qatar","home_code":"QAT","stadium":"BC Place, Vancouver","kickoff_utc":"2026-06-19T02:00:00Z","status":"scheduled","home_score":None,"away_score":None},
    # Group C
    {"id":5,"match_number":5,"round":"group","group_name":"C","home_team":"Haiti","home_code":"HAI","away_team":"Scotland","away_code":"SCO","stadium":"Gillette Stadium, Boston","kickoff_utc":"2026-06-14T02:00:00Z","status":"completed","home_score":1,"away_score":2},
    {"id":6,"match_number":6,"round":"group","group_name":"C","home_team":"Brazil","home_code":"BRA","away_team":"Morocco","away_code":"MAR","stadium":"MetLife Stadium, New Jersey","kickoff_utc":"2026-06-14T01:00:00Z","status":"completed","home_score":1,"away_score":1},
    {"id":21,"match_number":21,"round":"group","group_name":"C","home_team":"Scotland","away_code":"SCO","away_team":"Morocco","home_code":"MAR","stadium":"Gillette Stadium, Boston","kickoff_utc":"2026-06-19T19:00:00Z","status":"scheduled","home_score":None,"away_score":None},
    {"id":22,"match_number":22,"round":"group","group_name":"C","home_team":"Brazil","home_code":"BRA","away_team":"Haiti","home_code":"HAI","stadium":"Lincoln Financial Field, Philadelphia","kickoff_utc":"2026-06-19T22:00:00Z","status":"scheduled","home_score":None,"away_score":None},
    # Group D
    {"id":7,"match_number":7,"round":"group","group_name":"D","home_team":"USA","home_code":"USA","away_team":"Paraguay","away_code":"PAR","stadium":"SoFi Stadium, Los Angeles","kickoff_utc":"2026-06-13T01:00:00Z","status":"completed","home_score":4,"away_score":1},
    {"id":8,"match_number":8,"round":"group","group_name":"D","home_team":"Australia","home_code":"AUS","away_team":"Türkiye","away_code":"TUR","stadium":"BC Place, Vancouver","kickoff_utc":"2026-06-13T22:00:00Z","status":"completed","home_score":0,"away_score":1},
    {"id":23,"match_number":23,"round":"group","group_name":"D","home_team":"USA","home_code":"USA","away_team":"Australia","home_code":"AUS","stadium":"Lumen Field, Seattle","kickoff_utc":"2026-06-19T19:00:00Z","status":"scheduled","home_score":None,"away_score":None},
    {"id":24,"match_number":24,"round":"group","group_name":"D","home_team":"Paraguay","away_code":"PAR","away_team":"Türkiye","home_code":"TUR","stadium":"Levi's Stadium, Santa Clara","kickoff_utc":"2026-06-19T22:00:00Z","status":"scheduled","home_score":None,"away_score":None},
    # Group E
    {"id":9,"match_number":9,"round":"group","group_name":"E","home_team":"Côte d'Ivoire","home_code":"CIV","away_team":"Ecuador","away_code":"ECU","stadium":"Lincoln Financial Field, Philadelphia","kickoff_utc":"2026-06-14T17:00:00Z","status":"scheduled","home_score":None,"away_score":None},
    {"id":10,"match_number":10,"round":"group","group_name":"E","home_team":"Germany","home_code":"GER","away_team":"Curaçao","away_code":"CUW","stadium":"NRG Stadium, Houston","kickoff_utc":"2026-06-15T01:00:00Z","status":"scheduled","home_score":None,"away_score":None},
    {"id":25,"match_number":25,"round":"group","group_name":"E","home_team":"Ecuador","away_code":"ECU","away_team":"Curaçao","home_code":"CUW","stadium":"Mercedes-Benz Stadium, Atlanta","kickoff_utc":"2026-06-20T17:00:00Z","status":"scheduled","home_score":None,"away_score":None},
    {"id":26,"match_number":26,"round":"group","group_name":"E","home_team":"Côte d'Ivoire","home_code":"CIV","away_team":"Germany","home_code":"GER","stadium":"NRG Stadium, Houston","kickoff_utc":"2026-06-20T20:00:00Z","status":"scheduled","home_score":None,"away_score":None},
    # Group F
    {"id":11,"match_number":11,"round":"group","group_name":"F","home_team":"Argentina","home_code":"ARG","away_team":"Algeria","away_code":"ALG","stadium":"Arrowhead Stadium, Kansas City","kickoff_utc":"2026-06-16T17:00:00Z","status":"scheduled","home_score":None,"away_score":None},
    {"id":12,"match_number":12,"round":"group","group_name":"F","home_team":"England","home_code":"ENG","away_team":"Croatia","away_code":"CRO","stadium":"AT&T Stadium, Dallas","kickoff_utc":"2026-06-17T17:00:00Z","status":"scheduled","home_score":None,"away_score":None},
    {"id":27,"match_number":27,"round":"group","group_name":"F","home_team":"Croatia","away_code":"CRO","away_team":"Algeria","home_code":"ALG","stadium":"Hard Rock Stadium, Miami","kickoff_utc":"2026-06-21T17:00:00Z","status":"scheduled","home_score":None,"away_score":None},
    {"id":28,"match_number":28,"round":"group","group_name":"F","home_team":"Argentina","home_code":"ARG","away_team":"England","home_code":"ENG","stadium":"MetLife Stadium, New Jersey","kickoff_utc":"2026-06-21T20:00:00Z","status":"scheduled","home_score":None,"away_score":None},
    # Group G
    {"id":13,"match_number":13,"round":"group","group_name":"G","home_team":"France","home_code":"FRA","away_team":"Senegal","away_code":"SEN","stadium":"MetLife Stadium, New Jersey","kickoff_utc":"2026-06-16T20:00:00Z","status":"scheduled","home_score":None,"away_score":None},
    {"id":14,"match_number":14,"round":"group","group_name":"G","home_team":"Spain","home_code":"ESP","away_team":"Uzbekistan","home_code":"UZB","stadium":"Estadio BBVA, Monterrey","kickoff_utc":"2026-06-17T20:00:00Z","status":"scheduled","home_score":None,"away_score":None},
    {"id":29,"match_number":29,"round":"group","group_name":"G","home_team":"Senegal","away_code":"SEN","away_team":"Uzbekistan","home_code":"UZB","stadium":"AT&T Stadium, Dallas","kickoff_utc":"2026-06-22T17:00:00Z","status":"scheduled","home_score":None,"away_score":None},
    {"id":30,"match_number":30,"round":"group","group_name":"G","home_team":"France","home_code":"FRA","away_team":"Spain","home_code":"ESP","stadium":"SoFi Stadium, Los Angeles","kickoff_utc":"2026-06-22T20:00:00Z","status":"scheduled","home_score":None,"away_score":None},
    # Group H
    {"id":15,"match_number":15,"round":"group","group_name":"H","home_team":"Portugal","home_code":"POR","away_team":"Ghana","home_code":"GHA","stadium":"FedExField, Washington DC","kickoff_utc":"2026-06-17T23:00:00Z","status":"scheduled","home_score":None,"away_score":None},
    {"id":16,"match_number":16,"round":"group","group_name":"H","home_team":"Netherlands","home_code":"NED","away_team":"Colombia","home_code":"COL","stadium":"Mercedes-Benz Stadium, Atlanta","kickoff_utc":"2026-06-18T01:00:00Z","status":"scheduled","home_score":None,"away_score":None},
    {"id":31,"match_number":31,"round":"group","group_name":"H","home_team":"Colombia","away_code":"COL","away_team":"Ghana","home_code":"GHA","stadium":"FedExField, Washington DC","kickoff_utc":"2026-06-23T17:00:00Z","status":"scheduled","home_score":None,"away_score":None},
    {"id":32,"match_number":32,"round":"group","group_name":"H","home_team":"Portugal","home_code":"POR","away_team":"Netherlands","home_code":"NED","stadium":"NRG Stadium, Houston","kickoff_utc":"2026-06-23T20:00:00Z","status":"scheduled","home_score":None,"away_score":None},
]

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

def get_matches():
    return REAL_MATCHES

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
    matches = get_matches()
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

    mlist = get_matches()
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
