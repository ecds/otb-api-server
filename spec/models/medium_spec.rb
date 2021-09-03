# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Medium, type: :model do
  it { should have_many(:stop_media) }
  it { should have_many(:stops) }

  context 'video' do
    it 'gets image from youtube and sets embed' do
      medium = create(:medium, video: 'F9ULbmCvmxY', base_sixty_four: nil, video_provider: 'youtube')
      expect(medium.embed).to eq("//www.youtube.com/embed/#{medium.video}")
      expect(medium.file.attached?).to be true
    end

    it 'gets nothing when YouTube video is not found' do
      medium = create(:medium, video: 'CvmxYF9ULbm', base_sixty_four: nil, video_provider: 'youtube')
      expect(medium.embed).to be nil
      expect(medium.provider).to be nil
      expect(medium.file.attached?).to be false
    end

    it 'gets image from vimeo and sets embed' do
      medium = create(:medium, video: '310645255', base_sixty_four: nil, video_provider: 'vimeo')
      expect(medium.embed).to eq("//player.vimeo.com/video/#{medium.video}")
      expect(medium.file.attached?).to be true
    end

    it 'gets image from soundcloud and sets embed' do
      iframe = '<iframe width="100%" height="300" scrolling="no" frameborder="no" allow="autoplay" src="https://w.soundcloud.com/player/?url=https%3A//api.soundcloud.com/tracks/457871163&color=%23ff5500&auto_play=false&hide_related=false&show_comments=true&show_user=true&show_reposts=false&show_teaser=true&visual=true"></iframe><div style="font-size: 10px; color: #cccccc;line-break: anywhere;word-break: normal;overflow: hidden;white-space: nowrap;text-overflow: ellipsis; font-family: Interstate,Lucida Grande,Lucida Sans Unicode,Lucida Sans,Garuda,Verdana,Tahoma,sans-serif;font-weight: 100;"><a href="https://soundcloud.com/fiendbassy" title="FiendBassy" target="_blank" style="color: #cccccc; text-decoration: none;">FiendBassy</a> · <a href="https://soundcloud.com/fiendbassy/boca-raton-feat-a-ap-ferg" title="Boca Raton (with A$AP Ferg)" target="_blank" style="color: #cccccc; text-decoration: none;">Boca Raton (with A$AP Ferg)</a></div>'
      medium = create(:medium, video: iframe, base_sixty_four: nil, video_provider: 'soundcloud')
      expect(medium.embed).to eq("//w.soundcloud.com/player/?url=https%3A//api.soundcloud.com/tracks/#{medium.video}&color=%23ff5500&auto_play=false&hide_related=true&show_comments=false&show_user=false&show_reposts=false&show_teaser=false&visual=true&sharing=false")
      expect(medium.file.attached?).to be true
      expect(medium.title).to eq('FiendBassy: Boca Raton (with A$AP Ferg)')
    end

    it 'gets default image from when no image found for soundcloud and sets embed' do
      iframe = '<iframe width="100%" height="300" scrolling="no" frameborder="no" allow="autoplay" src="https://w.soundcloud.com/player/?url=https%3A//api.soundcloud.com/tracks/431162745&color=%23ff5500&auto_play=false&hide_related=false&show_comments=true&show_user=true&show_reposts=false&show_teaser=true&visual=true"></iframe><div style="font-size: 10px; color: #cccccc;line-break: anywhere;word-break: normal;overflow: hidden;white-space: nowrap;text-overflow: ellipsis; font-family: Interstate,Lucida Grande,Lucida Sans Unicode,Lucida Sans,Garuda,Verdana,Tahoma,sans-serif;font-weight: 100;"><a href="https://soundcloud.com/user-270843798" title="Emory Center for Digital Scholarship" target="_blank" style="color: #cccccc; text-decoration: none;">Emory Center for Digital Scholarship</a> · <a href="https://soundcloud.com/user-270843798/6-subsatellite-launch" target="_blank" style="color: #cccccc; text-decoration: none;">Subsatellite Launch</a></div>'
      medium = create(:medium, video: iframe, base_sixty_four: nil, video_provider: 'soundcloud')
      expect(medium.embed).to eq("//w.soundcloud.com/player/?url=https%3A//api.soundcloud.com/tracks/#{medium.video}&color=%23ff5500&auto_play=false&hide_related=true&show_comments=false&show_user=false&show_reposts=false&show_teaser=false&visual=true&sharing=false")
      expect(medium.file.attached?).to be true
      expect(medium.title).to eq('Emory Center for Digital Scholarship')
    end
  end
end
