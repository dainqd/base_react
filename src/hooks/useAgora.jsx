import {useEffect, useState} from 'react'
import AgoraRTC from 'agora-rtc-sdk-ng';

/**
 * @description Hooks to get agora functions
 * @author jagannath
 * @date 22/04/2021
 * @param client
 * @return {*} {
 localAudioTrack,
 localVideoTrack,
 joinState,
 leave,
 Join,
 remoteUsers,
 }
 */
const useAgora = (client) => {
    const [localVideoTrack, setLocalVideoTrack] = useState();
    const [localAudioTrack, setLocalAudioTrack] = useState();
    const [joinState, setJoinState] = useState(false);
    const [remoteUsers, setRemoteUsers] = useState([]);

    useEffect(() => {
        // console.log('remoteUsers', client.remoteUsers)
        if (!client) return;
        setRemoteUsers(client.remoteUsers);

        const handleUserPublished = async (user, mediaType) => {
            console.log('user, mediaType', user, mediaType)
            await client.subscribe(user, mediaType);
            setRemoteUsers(remoteUsers => Array.from(client.remoteUsers));
        }
        const handleUserUnpublished = (user) => {
            setRemoteUsers(remoteUsers => Array.from(client.remoteUsers));
        }
        const handleUserJoined = (user) => {
            setRemoteUsers(remoteUsers => Array.from(client.remoteUsers));
        }
        const handleUserLeft = (user) => {
            setRemoteUsers(remoteUsers => Array.from(client.remoteUsers));
        }
        client.on('user-published', handleUserPublished);
        client.on('user-unpublished', handleUserUnpublished);
        client.on('user-joined', handleUserJoined);
        client.on('user-left', handleUserLeft);

        return () => {
            client.off('user-published', handleUserPublished);
            client.off('user-unpublished', handleUserUnpublished);
            client.off('user-joined', handleUserJoined);
            client.off('user-left', handleUserLeft);
        };
    }, [client]);

    const removeLocalVideoTracks = async () => {
        try {
            if (localVideoTrack) {
                await client.unpublish(localVideoTrack)
                localVideoTrack.stop();
                localVideoTrack.close();
                setLocalVideoTrack(null)
            }
        } catch (error) {
            console.error(error)
        }
    }

    const removeLocalAudioTracks = async () => {
        try {
            if (localAudioTrack) {
                await client.unpublish(localAudioTrack)
                localAudioTrack.stop();
                localAudioTrack.close();
                setLocalAudioTrack(null)
            }

        } catch (error) {
            console.error(error)
        }
    }

    const joinLocalVideoTrack = async () => {
        try {
            if (localVideoTrack) {
                console.log('localVideoTrack', localVideoTrack)
                await client.publish([localVideoTrack])
            } else {
                const cameraTrack = await AgoraRTC.createCameraVideoTrack()
                setLocalVideoTrack(cameraTrack);
                await client.publish(cameraTrack)
            }

        } catch (error) {
            console.error(error)
        }
    }
    const joinLocalAudioTrack = async () => {
        try {
            if (localAudioTrack) {
                await client.publish([localAudioTrack])
            } else {
                const microphoneTrack = await AgoraRTC.createMicrophoneAudioTrack()
                setLocalAudioTrack(microphoneTrack);
                await client.publish(microphoneTrack)
            }

        } catch (error) {
            console.error(error)
        }
    }

    /**
     * @description call this method to Join call with creds
     * @author jagannath
     * @date 22/04/2021
     * @param appid:String - agora app id
     * @param channel:String - Channel name
     * @param token?:String - token for role management
     * @param uid?:String- Integer - unique userid (default generated by agora)
     * @param options?:Object- other options)
     */
    const join = async (appid, channel, token = null, uid = null, options) => {
        console.log('options', options)
        if (!client) return;
        try {
            const tracks = [];
            let microphoneTrack;
            let cameraTrack;

            await client.join(appid, channel, token || null);
            if (options.audio) {
                microphoneTrack = await AgoraRTC.createMicrophoneAudioTrack()
                setLocalAudioTrack(microphoneTrack);
                tracks.push(microphoneTrack)
            }
            if (options.video) {
                cameraTrack = await AgoraRTC.createCameraVideoTrack()
                setLocalVideoTrack(cameraTrack);
                tracks.push(cameraTrack)
            }
            if (tracks?.length) {
                console.log('tracks', tracks)
                await client.publish(tracks);
            }

            window.client = client;
            window.videoTrack = cameraTrack;
            setJoinState(true);
        } catch (error) {
            console.error('Join error', error)
        }
    }

    const leave = async () => {
        if (localAudioTrack) {
            localAudioTrack.stop();
            localAudioTrack.close();
        }
        if (localVideoTrack) {
            localVideoTrack.stop();
            localVideoTrack.close();
        }
        setRemoteUsers([]);
        setJoinState(false);
        client.unpublish()
        await client?.leave();
    }

    return {
        localAudioTrack,
        localVideoTrack,
        joinState,
        leave,
        join,
        remoteUsers,
        removeLocalVideoTracks,
        removeLocalAudioTracks,
        joinLocalVideoTrack,
        joinLocalAudioTrack
    };
}

export default useAgora
