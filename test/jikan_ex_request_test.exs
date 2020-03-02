defmodule JikanExTest.Request do
  use ExUnit.Case, async: true
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  alias JikanEx.{Request}

  setup do
    ExVCR.Config.cassette_library_dir("fixture/vcr_cassettes")
    client = JikanEx.client()
    base_url = JikanEx.Base.get_base_url(client)
    {:ok, client: client, base_url: base_url}
  end

  test "base request succeeds", context do
    use_cassette "base_request_succeeds" do
      {:ok, response} = Request.request("anime/1", context[:client])
      assert response["http_url"] == "#{context[:base_url]}anime/1"
      assert response["title"] == "Cowboy Bebop"
    end
  end

  test "base request! succeeds", context do
    use_cassette "base_request_succeeds" do
      response = Request.request!("anime/1", context[:client])
      assert response["http_url"] == "#{context[:base_url]}anime/1"
      assert response["title"] == "Cowboy Bebop"
      assert Map.has_key?(response, "http_url")
      assert Map.has_key?(response, "http_status")
      assert Map.has_key?(response, "http_headers")
    end
  end

  test "base request fails", context do
    use_cassette "base_request_fails" do
      {:error, resp_error} = Request.request("something", context[:client])
      assert resp_error["http_status"] == 400
      assert resp_error["http_url"] == "https://api.jikan.moe/v3/something"
      assert resp_error["type"] == "HttpException"

      assert resp_error["message"] ==
               "Invalid or incomplete request. Please double check the request documentation"
    end
  end

  test "base request! fails", context do
    use_cassette "base_request_fails" do
      resp_error =
        assert_raise JikanEx.Exception, fn ->
          Request.request!("something", context[:client])
        end

      assert resp_error.response["message"] ==
               "Invalid or incomplete request. Please double check the request documentation"

      assert resp_error.message ==
               "HTTP Error 400: Invalid or incomplete request. Please double check the request documentation"
    end
  end

  test "anime succeeds", context do
    use_cassette "anime_succeeds" do
      {:ok, response} = Request.anime(context[:client], 26165)
      assert response["title"] == "Yuri Kuma Arashi"
      assert response["url"] == "https://myanimelist.net/anime/26165/Yuri_Kuma_Arashi"
      assert response["type"] == "TV"
      assert response["episodes"] == 12
    end
  end

  test "anime! succeeds", context do
    use_cassette "anime_succeeds" do
      response = Request.anime!(context[:client], 26165)
      assert response["url"] == "https://myanimelist.net/anime/26165/Yuri_Kuma_Arashi"
    end
  end

  test "anime! extension fails", context do
    use_cassette "anime_extension_fails" do
      _resp_error =
        assert_raise JikanEx.Exception, fn ->
          Request.anime!(context[:client], 26165, [:unknown_endpoint])
        end
    end
  end

  test "anime! extension succeeds", context do
    use_cassette "anime_extension_succeeds" do
      response = Request.anime!(context[:client], 199, ["characters_staff"])
      assert response["characters"] |> List.first() |> Map.get("name") == "Haku"
      assert response["staff"] |> Enum.at(2) |> Map.get("name") == "Miyazaki, Hayao"
    end
  end

  # only testing bang functions from here on wards, non bang work fine, according to the tests above
  #
  test "manga extension succeeds", context do
    use_cassette "manga_extension_succeeds" do
      response = Request.manga!(context[:client], 1, [:userupdates, 2])
      assert response |> Map.get("users") |> Enum.count() == 75
      assert response["http_url"] == "#{context[:base_url]}manga/1/userupdates/2"
    end
  end

  test "person succeeds", context do
    use_cassette "person_succeeds" do
      response = Request.person!(context[:client], 40135)
      assert response["name"] == "Rapparu"
      assert response["http_url"] == "#{context[:base_url]}person/40135"
    end
  end

  test "character succeeds", context do
    use_cassette "character_succeeds" do
      response = Request.character!(context[:client], 16)
      assert response["name"] == "Edward Wong Hau Pepelu Tivrusky IV"
      assert response["http_url"] == "#{context[:base_url]}character/16"
    end
  end

  test "search succeeds", context do
    use_cassette "search_succeeds" do
      response =
        Request.search!(context[:client], [:anime], %{:q => "Rakugo Shinjuu", :limit => 3})

      rakugo = response["results"] |> List.first()
      assert rakugo["airing"] == false
      assert rakugo["episodes"] == 13
      assert rakugo["title"] == "Shouwa Genroku Rakugo Shinjuu"
      assert String.contains?(response["http_url"], "Rakugo%20Shinjuu")
    end
  end

  # most recently approved entry
  test "search sfw entries, no query succeeds", context do
    use_cassette "search_sfw_entries_succeeds" do
      response =
        Request.search!(context[:client], [:anime], %{
          :q => "",
          :page => 1,
          :genre => 12,
          :genre_exclude => 0,
          :order_by => "id",
          :sort => "desc"
        })

      senyoku = response["results"] |> List.first()
      assert senyoku["title"] == "Senyoku no Sigrdrifa"

      assert response["http_url"] ==
               "#{context[:base_url]}search/anime?genre=12&genre_exclude=0&order_by=id&page=1&q=&sort=desc&"
    end
  end

  test "specific season succeeds", context do
    use_cassette "specific_season_succeeds" do
      response = Request.season!(context[:client], [2019, :winter])
      assert response["http_url"] == "#{context[:base_url]}season/2019/winter"

      assert response |> Map.get("anime") |> List.first() |> Map.get("title") ==
               "Tate no Yuusha no Nariagari"
    end
  end

  test "current season succeeds", context do
    use_cassette "current_season_succeeds" do
      response = Request.season!(context[:client])
      assert is_list(response["anime"])
      # this season has some anime
      assert length(response["anime"])
    end
  end

  test "current schedule succeeds", context do
    use_cassette "current_schedule_succeeds" do
      response = Request.schedule!(context[:client])

      assert MapSet.subset?(
               MapSet.new([
                 "monday",
                 "tuesday",
                 "wednesday",
                 "thursday",
                 "friday",
                 "saturday",
                 "sunday",
                 "other",
                 "unknown"
               ]),
               response |> Map.keys() |> MapSet.new()
             )
    end
  end

  test "top succeeds", context do
    use_cassette "top_succeeds" do
      response = Request.top!(context[:client], [:manga])
      assert response["top"] |> List.first() |> Map.get("title") == "Berserk"
    end
  end

  test "genre succeeds", context do
    use_cassette "genre_succeeds" do
      response = Request.genre!(context[:client], [:anime, 5, 2])
      assert response["mal_url"]["url"] == "https://myanimelist.net/anime/genre/5/Dementia?page=2"
    end
  end

  test "producer succeeds", context do
    use_cassette "producer_succeeds" do
      response = Request.producer!(context[:client], 2)
      assert response["meta"]["name"] == "Kyoto Animation"
    end
  end

  test "magazine succeeds", context do
    use_cassette "magazine_succeeds" do
      response = Request.magazine!(context[:client], 21)
      assert response["meta"]["name"] == "Hana to Yume"
    end
  end

  test "club succeeds", context do
    use_cassette "club_succeeds" do
      response = Request.club!(context[:client], 72940)
      assert response["created"] == "2016-12-29T00:00:00+00:00"
      assert response["url"] == "https://myanimelist.net/clubs.php?cid=72940"
      assert response["title"] == "Minna no Uta"
    end
  end

  test "meta succeeds", context do
    use_cassette "meta_succeeds" do
      response = Request.meta!(context[:client], [:requests, :anime, :today])
      assert response["http_url"] == "#{context[:base_url]}meta/requests/anime/today"
    end
  end

  test "user profile succeeds", context do
    use_cassette "user_profile_succeeds" do
      response = Request.user!(context[:client], :purplepinapples, [:profile])
      assert response["anime_stats"]["dropped"] == 12058
      assert response["user_id"] == 4_837_235
      assert is_nil(response["birthday"])
    end
  end

  test "user animelist succeeds", context do
    use_cassette "user_animelist_succeeds" do
      response =
        Request.user!(context[:client], :purplepinapples, [:animelist, :completed], %{
          :order_by => "score",
          :sort => "desc"
        })

      assert response["anime"] |> List.first() |> Map.get("title") == "Cowboy Bebop"
    end
  end
end
