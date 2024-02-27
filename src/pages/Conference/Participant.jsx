import React from 'react'
import MediaPlayer from '../../components/MediaPlayer'

const Participant = (props) => {
    return (
        <div className="border h-100">
            <MediaPlayer
                videoTrack={props.videoTrack}
                audioTrack={props.audioTrack}
                avatarSize="100px"
            />
        </div>
    )
}

export default Participant
