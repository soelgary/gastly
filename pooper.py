import uuid

class Pooper(object):
  def __init__(self, room=None):
    self._id = str(uuid.uuid4().int)
    self._room = room

  def set_room(self, room):
    self._room = room

  def get_room(self):
    return self._room

  def get_id(self):
    return self._id