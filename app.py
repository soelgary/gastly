from flask import Flask, render_template, session, request, jsonify
from flask.ext.socketio import SocketIO, emit, join_room, leave_room
from pooper import Pooper
from threading import Thread
from flask import session
import uuid

app = Flask(__name__)
app.debug = True
app.config['SECRET_KEY'] = 'secret!'
socketio = SocketIO(app)

chatless_poopers = list()

def generate_room():
  return 'room-' + str(uuid.uuid4().int)

def find_room(pooper):
  print 'finding a room'
  if not chatless_poopers:
    print 'no poopers'
    room = generate_room()
    pooper.set_room(room)
    chatless_poopers.append(pooper)
    return room
  print 'poopers', chatless_poopers
  pooper = chatless_poopers.pop()
  return pooper.get_room()

@socketio.on('initialize', namespace='/poopchat')
def connect(message):
  pooper = Pooper()
  room = find_room(pooper)
  join_room(room)
  session['room'] = room
  session['id'] = pooper.get_id()
  emit('initialize', {'id': session['id'], 'room': session['room']})
  print 'we have a new pooper', pooper.get_id()
  print "Connect Session", session

@socketio.on('send', namespace='/poopchat')
def receive_message(message):
  print 'Received a message', message
  print 'the session is', session
  emit('message', {'message': message}, room=session['room'])

@socketio.on('disconnect', namespace='/poopchat')
def test_disconnect():
    print('Client disconnected')

if __name__ == '__main__':
    socketio.run(app, host='127.0.0.1', port=5555)
