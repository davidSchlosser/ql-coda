#!/usr/bin/env python3
"""
Invokes a command received in a message via a subscribed Mqtt topic. Commands are indicated by a key token
which retrieves the command syntax from a set of supported commands in the configuration file,
qlbridge.conf

Message commands consist of a single word key (lower case only) and one or more argument tokens.
Double quote command argument tokens to handle argument tokens containing spaces.
eg: genre "'Classical - Guitar'"
"""
import logging
import os
import shlex
import subprocess
import sys
import base64
import json
# import queue, time
import random
import string
import math
from configparser import ConfigParser
# from threading import Timer
from sys import exit

import paho.mqtt.client as mqtt
from albumsFromJsonSongDetails import albumsFromJsonSongDetails

# import json
# from subprocess import Popen, PIPE

# defaults
BROKER_HOST = "192.168.1.253"
# BROKER_HOST = "localhost"
BROKER_PORT = 1883
TOPIC_CONTROL = "mqinvoke/control"
TOPIC_RESPONSE = "mqinvoke/response"
TOPIC_RPC = "mqinvoke/rpc"
TOPIC_NOW_PLAYING = "quodlibet/now-playing"
TOPIC_COVER = 'mqinvoke/cover-image'

logging.basicConfig(level=logging.DEBUG, format='%(levelname)s:%(message)s')
logging.captureWarnings(False)

cover_publishing_queue = []


class InvokeListener:
    topic_cover: str

    def __init__(self, invoker, broker=BROKER_HOST, port=BROKER_PORT, topic_ctl=TOPIC_CONTROL,
                 topic_rpc=TOPIC_RPC, topic_now_playing=TOPIC_NOW_PLAYING, topic_cover=TOPIC_COVER):
        self.client = client = mqtt.Client("mqinvoke")
        client.on_connect = self.on_connect
        client.on_message = self.on_message
        client.connect(broker, port, 60)
        logging.debug("mqinvoke: wait for broker connection")
        self.topic_ctl = topic_ctl
        self.topic_rpc = topic_rpc
        self.topic_now_playing = topic_now_playing
        self.topic_cover = topic_cover
        self.invoker = invoker
        self.client.loop_start()

    def on_connect(self, client, _userdata, _flags, rc):
        logging.info("broker connected with result code " + str(rc))
        client.subscribe(self.topic_ctl)
        client.subscribe(self.topic_rpc)
        client.subscribe(self.topic_now_playing)

    def on_message(self, client, _userdata, msg):
        logging.info("payload: %s", msg.payload)
        try:
            # ctl = str(msg.payload.decode("ISO-8859-1"))
            ctl = str(msg.payload.decode("utf-8"))
        except Exception as e:
            logging.debug("exception %s", str(e))
            return
        logging.debug("mqinvoke: " + msg.topic + " " + ctl)
        match msg.topic:
            case self.topic_ctl:
                # used for control requests like play, pause, next etc
                response = self.invoker.invoke(ctl)
                if response != '':
                    client.publish(topic_response, payload=response)
            case self.topic_rpc:
                # 'rpc' calls arrives from the caller with a unique ID to identify a topic to use for the reply message
                # This topic is used for 'rpc' calls to get the playlist, tag values etc
                logging.debug('rpc --%s--', ctl)
                try:
                    op = json.loads(ctl)
                    rpc_topic = op['replyTopic']
                    action = op['op']
                    args = op.get('args', '')
                    # logging.debug('op: %s, args: %s, replyTopic: %s', action, args, rpc_topic)
                    response = self.invoker.invoke(action + ' ' + ' '.join(args))
                    # logging.debug('response: %s', response)
                    if response:
                        client.publish(rpc_topic, payload=response)
                except Exception as e:
                    logging.debug("exception: %s", str(e))

            case self.topic_now_playing:
                # TODO check if the cover filename is in the message
                logging.debug("now playing: %s", ctl)
                if ctl:
                    nowPlaying = json.loads(ctl)
                    cover_file_name = nowPlaying['cover'] if 'cover' in nowPlaying else ''
                    logging.debug("cover file name: %s", cover_file_name)
                    if cover_file_name:
                        self.publish_encoded_image(cover_file_name, nowPlaying['trackData']['title'])

                '''
                _l: list[str] = ctl.split('\n')
                if _l and '=' in ctl:
                    logging.debug('now_playing: %s', _l)
                    _d: dict = {i.split('=')[0]: i.split('=')[1] for i in _l}
                    cover_file_name = _d['cover'] if 'cover' in _d else ''
                    logging.debug("cover file name: %s", cover_file_name)
                    self.publish_encoded_image(cover_file_name, _d['title'])
                '''

            case _:
                print('unknown topic')

    @staticmethod
    def publish_encoded_image(image_file_name, _song_title):
        global image_packet_size
        pic_id = "_ql_" + randomword(8)
        # from datetime import datetime
        with open(image_file_name, 'rb') as image_file:
            img = image_file.read()
            encoded_bytes = base64.b64encode(img)
            encoded = encoded_bytes.decode('utf-8')  # bytes to string
        end = image_packet_size
        start = 0
        length = len(encoded)
        pos = 0
        no_of_packets = math.ceil(length / image_packet_size)
        # logging.debug("publish cover image id: %s in %d packetsX." % (pic_id, no_of_packets))
        while start <= len(encoded):
            data = {"name": "",
                    "data": encoded[start:end],
                    "pic_id": pic_id,
                    "pos": pos,
                    "size": no_of_packets}
            #
            # queue the data to be published in the main thread
            #
            cover_publishing_queue.append(data)
            end += image_packet_size
            start += image_packet_size
            pos = pos + 1
        # self.client.reconnect()

    '''def monitor(self, delay, action, timer=None):
        self.timer = RepeatTimer(delay, self.on_monitor_timer, action)
        self.timer.start()

    def on_monitor_timer(self, *args):
        response = self.invoker.process(args)
        self.client.publish(topic_response, payload=response)
    '''


class Invoker:
    def __init__(self, ctls):
        self.ctls = ctls

    def multiLineJson(self, linesOfJson):
        decodedLines = []
        for line in linesOfJson.splitlines():
            if line != '':
                decodedLines.append(json.loads(line[1:-1]))
        result = json.dumps(decodedLines)
        logging.debug('fetchqueue as json: %s', result)
        return result

    def invoke(self, ctl):
        tokens = shlex.split(ctl)  # handle quoted tokens eg 'Jazz- Guitar'
        try:
            key = tokens.pop(0)
            if key in self.ctls:
                match key:
                    case 'fetchqueue':
                        args = [
                            '/home/david/quodlibet/quodlibet.py',
                            '--print-queue',
                            '--with-pattern=\'<~json>\''
                        ]
                        process = subprocess.run(args, universal_newlines=True, capture_output=True)
                        logging.debug('fetchqueue stdout: %s', process.stdout)
                        logging.debug('fetchqueue stderr: %s', process.stderr)
                        return self.multiLineJson(process.stdout)

                    case 'clearqueue':
                        args = [
                            '/home/david/quodlibet/quodlibet.py',
                            '--unqueue='
                        ]
                        process = subprocess.run(args, universal_newlines=True, capture_output=True)
                        logging.debug('clearqueue stdout: %s', process.stdout)
                        logging.debug('clearqueue stderr: %s', process.stderr)
                        return

                    case 'unqueue':
                        filename =  tokens.pop(0)
                        args = [
                            '/home/david/quodlibet/quodlibet.py',
                            '--unqueue=' + filename
                        ]
                        process = subprocess.run(args, universal_newlines=True, capture_output=True)
                        logging.debug('unqueue stdout: %s', process.stdout)
                        logging.debug('unqueue stderr: %s', process.stderr)
                        return

                    case 'enqueue':
                        filename =  tokens.pop(0)   #.replace('\'', '\\\'')
                        args = [
                            '/home/david/quodlibet/quodlibet.py',
                            '--enqueue=' + filename
                        ]
                        process = subprocess.run(args, universal_newlines=True, capture_output=True)
                        logging.debug('unqueue stdout: %s', process.stdout)
                        logging.debug('unqueue stderr: %s', process.stderr)
                        return

                    case 'enqueuealbum':
                        dirname = tokens.pop(0).replace('\'', '\\\'')
                        args = [
                            '/home/david/quodlibet/quodlibet.py',
                            '--print-query=~dirname=\'' + dirname + '\''
                        ]
                        process = subprocess.run(args, universal_newlines=True, capture_output=True)
                        logging.debug('stdout(get songFiles): %s', process.stdout)
                        logging.debug('stderr(get songFiles): %s', process.stderr)
                        songFiles = process.stdout.split('\n')
                        for songFile in songFiles:
                            args[1] = '--enqueue=' + songFile
                            process = subprocess.run(args, universal_newlines=True, capture_output=True)
                            logging.debug('stdout(enqueue %s): %s', songFile, process.stdout)
                            logging.debug('stderr(enqueue %s): %s', songFile, process.stderr)
                        return

                    case 'exporttags':
                        filename = tokens.pop(0)
                        args = [
                            '/home/david/quodlibet/operon.py',
                            'print',
                            '-p\'<~json>\'',
                            filename
                        ]
                        process = subprocess.run(args, universal_newlines=True, capture_output=True)
                        logging.debug('exporttags stdout: %s', process.stdout)
                        logging.debug('exporttags stderr: %s', process.stderr)

                        rtn = process.stdout[1:-2]
                        logging.debug('exporttags: %s', rtn)

                        return rtn #process.stdout.replace('\n', ',')

                    case 'replacetags':
                        j = tokens.pop(0)
                        replacement = json.loads(j)
                        args = [
                            '/home/david/quodlibet/operon.py',
                            'clear',
                            '--all'
                        ] + replacement['tracks']
                        process = subprocess.run(args, universal_newlines=True, capture_output=True)
                        logging.debug('stdout(clear tags): %s', process.stdout)
                        logging.debug('stderr(clear tags): %s', process.stderr)
                        for tag in replacement['tags']:
                            args = [
                               '/home/david/quodlibet/operon.py',
                               'add',
                               tag['name'],
                               tag['value']
                           ] + replacement['tracks']
                            process = subprocess.run(args, universal_newlines=True, capture_output=True)
                            logging.debug('stdout(add tag): %s', process.stdout)
                            logging.debug('stderr(add tags): %s', process.stderr)
                        return

                    case 'addtags':
                        j = tokens.pop(0)
                        replacement = json.loads(j)
                        for tag in replacement['tags']:
                            args = [
                               '/home/david/quodlibet/operon.py',
                               'add',
                               tag['name'],
                               tag['value']
                           ] + replacement['tracks']
                        process = subprocess.run(args, universal_newlines=True, capture_output=True)
                        logging.debug('stdout(add tags): %s', process.stdout)
                        logging.debug('stderr(add tags): %s', process.stderr)

                    case 'removetags':
                        j = tokens.pop(0)
                        replacement = json.loads(j)
                        for tag in replacement['tags']:
                            args = [
                               '/home/david/quodlibet/operon.py',
                               'remove',
                               tag['name'],
                               tag['value']
                           ] + replacement['tracks']
                        process = subprocess.run(args, universal_newlines=True, capture_output=True)
                        logging.debug('stdout(remove tags): %s', process.stdout)
                        logging.debug('stderr(remove tags): %s', process.stderr)
                        return

                    case 'fetchalbumtracks':
                        dirname = tokens.pop(0).replace('\'', '\\\'')
                        args = [
                            '/home/david/quodlibet/quodlibet.py',
                            '--print-query=~dirname=\'' + dirname + '\'',
                            '--with-pattern=\'<~json>\''
                        ]
                        process = subprocess.run(args, universal_newlines=True, capture_output=True)
                        logging.debug('stdout(get songFiles): %s', process.stdout)
                        logging.debug('stderr(get songFiles): %s', process.stderr)
                        return self.multiLineJson(process.stdout)

                    case 'playfile':
                        filename = tokens.pop(0)  # .replace('\'', '\\\'')
                        args = [
                            '/home/david/quodlibet/quodlibet.py',
                            '--play-file=' + filename
                        ]
                        process = subprocess.run(args, universal_newlines=True, capture_output=True)
                        logging.debug('unqueue stdout: %s', process.stdout)
                        logging.debug('unqueue stderr: %s', process.stderr)
                        return

                    case 'playlist':
                        args = [
                            '/home/david/quodlibet/quodlibet.py',
                            '--print-playlist',
                            '--with-pattern=\'<~json>\''
                        ]
                        process = subprocess.run(args, universal_newlines=True, capture_output=True)
                        logging.debug('stdout(playlist): %s', process.stdout)
                        logging.debug('stderr(playlist): %s', process.stderr)
                        return self.multiLineJson(process.stdout)

                    case 'queryalbums':
                        queryString = tokens.pop(0)
                        args = [
                            '/home/david/quodlibet/quodlibet.py',
                            '--with-pattern=\'<~json>\'',
                            '--print-query=' + queryString
                        ]
                        process = subprocess.run(args, universal_newlines=True, capture_output=True)
                        logging.debug('stdout(queryalbums): %s', process.stdout)
                        logging.debug('stderr(queryalbums): %s', process.stderr)
                        return albumsFromJsonSongDetails(process.stdout)

                    case 'seek':
                        pos = tokens.pop(0)
                        args = [
                            '/home/david/quodlibet/quodlibet.py',
                            '--seek=' + pos
                        ]
                        process = subprocess.run(args, universal_newlines=True, capture_output=True)
                        logging.debug('seek stdout: %s', process.stdout)
                        logging.debug('seek stderr: %s', process.stderr)
                        return

                    case _:
                        action = list(self.ctls[key])  # look up & copy the action template
                        if len(action) > 1:
                            # handle templates of form: genre = quodlibet --filter=genre={}
                            action[1] = action[1].format(*tokens)
                        return self.process(action)
            else:
                logging.debug("invalid command key: %s", key)
                return ''
        except Exception as e:
            logging.debug("exception: %s", str(e))
            return ''

    @staticmethod
    def process(action):
        logging.debug('action: %s', str(action))
        process = subprocess.run(action, universal_newlines=True, capture_output=True)
        #process = subprocess.run(action, universal_newlines=True, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        logging.debug('stdout: %s', process.stdout)
        logging.debug('stderr: %s', process.stderr)
        return process.stdout


'''
class RepeatTimer(Timer):
    def run(self):
        while not self.finished.wait(self.interval):
            self.function(*self.args, **self.kwargs)
'''

image_packet_size = 1024


# generate a string to use as image ID
def randomword(_length):
    return ''.join(random.choice(string.ascii_lowercase) for _ in range(_length))


if __name__ == '__main__':
    cf = ConfigParser()
    cf.read(os.path.dirname(sys.argv[0]) + '/qlbridge.conf')

    broker = cf['mqtt']['broker'] if 'broker' in cf['mqtt'] else BROKER_HOST
    port = int(cf['mqtt']['port']) if 'port' in cf['mqtt'] else BROKER_PORT
    topic_ctl = cf['mqtt']['topic_ctl'] if 'topic_ctl' in cf['mqtt'] else TOPIC_CONTROL
    topic_response = cf['mqtt']['topic_response'] if 'topic_response' in cf['mqtt'] else TOPIC_RESPONSE
    topic_cover = cf['mqtt']['topic_cover'] if 'topic_cover' in cf['mqtt'] else TOPIC_COVER
    logging.info('broker: %s, port:%s, control:%s, response:%s, cover: %s',
                 broker, port, topic_ctl, topic_response, topic_cover)

    if 'controls' not in cf.sections():
        logging.error('no invocation controls defined')
        exit(1)

    controls = cf['controls']
    ctls = {}
    for k, ctl in controls.items():
        ctls[k] = ctl.split()
        logging.debug('registered %s: %s' % (k, ctls[k]))

    invoker = Invoker(ctls)
    il = InvokeListener(invoker, broker, port, topic_ctl)

    '''
    monitors = cf['monitor']
    il.monitor(int(monitors['delay']), shlex.split(monitors['script']))
    '''

    while True:
        # TODO fix error
        if cover_publishing_queue:
            data = cover_publishing_queue.pop(0)
            #logging.debug('cover data %s', data)
            msg_info = il.client.publish(il.topic_cover, payload=json.JSONEncoder().encode(data))
            # msg_info = il.client.publish(il.topic_cover, payload="hello")
            msg_info.wait_for_publish()
        pass
