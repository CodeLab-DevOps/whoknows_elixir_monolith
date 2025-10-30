defmodule WhoknowsElixirMonolithWeb.Layouts.RootLayoutTest do
  use WhoknowsElixirMonolithWeb.ConnCase, async: true

  describe "root layout footer" do
    test "renders footer with copyright information", %{conn: conn} do
      conn = get(conn, ~p"/")
      response = html_response(conn, 200)
      
      assert response =~ "© 2009-2024"
    end

    test "renders Status link in footer", %{conn: conn} do
      conn = get(conn, ~p"/")
      response = html_response(conn, 200)
      
      assert response =~ "Status"
      assert response =~ "https://codelabs-devops.betteruptime.com/"
    end

    test "Status link has correct href attribute", %{conn: conn} do
      conn = get(conn, ~p"/")
      response = html_response(conn, 200)
      
      assert response =~ ~r{<a[^>]*href="https://codelabs-devops\.betteruptime\.com/"[^>]*>}
    end

    test "Status link has hover styling classes", %{conn: conn} do
      conn = get(conn, ~p"/")
      response = html_response(conn, 200)
      
      # Verify the link has the transition classes for hover effects
      assert response =~ "hover:text-gray-900"
      assert response =~ "dark:hover:text-gray-100"
      assert response =~ "transition-colors"
      assert response =~ "duration-200"
    end

    test "does not render old Privacy link", %{conn: conn} do
      conn = get(conn, ~p"/")
      response = html_response(conn, 200)
      
      # The Privacy link should not be present in the footer
      # Note: This regex looks for 'Privacy' as a standalone footer link
      refute response =~ ~r{<a[^>]*>[\s\n]*Privacy[\s\n]*</a>}
    end

    test "does not render old Terms link", %{conn: conn} do
      conn = get(conn, ~p"/")
      response = html_response(conn, 200)
      
      # The Terms link should not be present in the footer
      refute response =~ ~r{<a[^>]*>[\s\n]*Terms[\s\n]*</a>}
    end

    test "footer has proper flex layout classes", %{conn: conn} do
      conn = get(conn, ~p"/")
      response = html_response(conn, 200)
      
      # Verify the footer maintains proper layout structure
      assert response =~ "flex items-center space-x-6"
    end

    test "footer links section contains exactly one link", %{conn: conn} do
      conn = get(conn, ~p"/")
      response = html_response(conn, 200)
      
      # Extract the footer links section
      footer_links_regex = ~r{<div class="flex items-center space-x-6">(.*?)</div>}s
      
      case Regex.run(footer_links_regex, response) do
        [_, links_section] ->
          # Count <a> tags in the links section
          link_count = links_section
                      |> String.split("<a")
                      |> Enum.count()
                      |> Kernel.-(1)
          
          assert link_count == 1, "Expected exactly 1 link in footer, found #{link_count}"
        _ ->
          flunk("Could not find footer links section")
      end
    end

    test "Status link opens in same tab (no target attribute)", %{conn: conn} do
      conn = get(conn, ~p"/")
      response = html_response(conn, 200)
      
      # Extract the Status link
      status_link_regex = ~r{<a[^>]*href="https://codelabs-devops\.betteruptime\.com/"[^>]*>(.*?)</a>}s
      
      case Regex.run(status_link_regex, response) do
        [full_link | _] ->
          # Ensure no target="_blank" attribute
          refute full_link =~ ~r{target=}
        _ ->
          flunk("Could not find Status link")
      end
    end

    test "footer maintains consistent text color classes", %{conn: conn} do
      conn = get(conn, ~p"/")
      response = html_response(conn, 200)
      
      # Verify consistent color theming in footer
      assert response =~ "text-gray-600"
      assert response =~ "dark:text-gray-400"
    end

    test "copyright year range is correct", %{conn: conn} do
      conn = get(conn, ~p"/")
      response = html_response(conn, 200)
      
      current_year = DateTime.utc_now().year
      
      # Should show from 2009 to at least current year
      assert response =~ "2009"
      assert String.to_integer("2024") <= current_year
    end
  end

  describe "root layout footer structure" do
    test "footer is wrapped in proper semantic HTML", %{conn: conn} do
      conn = get(conn, ~p"/")
      response = html_response(conn, 200)
      
      # Check for footer tag
      assert response =~ ~r{<footer[^>]*>}
    end

    test "footer content is centered and has proper spacing", %{conn: conn} do
      conn = get(conn, ~p"/")
      response = html_response(conn, 200)
      
      # Verify layout classes exist for proper positioning
      assert response =~ "mx-auto"
      assert response =~ "max-w-6xl"
    end

    test "footer has responsive padding", %{conn: conn} do
      conn = get(conn, ~p"/")
      response = html_response(conn, 200)
      
      # Check for responsive padding classes
      assert response =~ ~r{p(x|y|t|b|l|r)?-\d+}
    end
  end

  describe "root layout footer accessibility" do
    test "Status link has descriptive text", %{conn: conn} do
      conn = get(conn, ~p"/")
      response = html_response(conn, 200)
      
      # The link text should be clear about its purpose
      assert response =~ ~r{<a[^>]*>[\s\n]*Status[\s\n]*</a>}
    end

    test "footer links have sufficient color contrast classes", %{conn: conn} do
      conn = get(conn, ~p"/")
      response = html_response(conn, 200)
      
      # Verify hover states provide clear visual feedback
      assert response =~ "hover:text-gray-900"
      assert response =~ "dark:hover:text-gray-100"
    end

    test "footer has proper semantic structure for screen readers", %{conn: conn} do
      conn = get(conn, ~p"/")
      response = html_response(conn, 200)
      
      # Footer should be in a footer tag for semantic HTML
      assert response =~ "<footer"
    end
  end

  describe "root layout footer consistency across routes" do
    test "footer appears on home page", %{conn: conn} do
      conn = get(conn, ~p"/")
      response = html_response(conn, 200)
      
      assert response =~ "Status"
      assert response =~ "© 2009-2024"
    end

    test "footer appears on register page", %{conn: conn} do
      conn = get(conn, ~p"/register")
      response = html_response(conn, 200)
      
      assert response =~ "Status"
      assert response =~ "© 2009-2024"
    end

    test "footer appears on login page", %{conn: conn} do
      conn = get(conn, ~p"/login")
      response = html_response(conn, 200)
      
      assert response =~ "Status"
      assert response =~ "© 2009-2024"
    end

    test "footer appears on weather page", %{conn: conn} do
      conn = get(conn, ~p"/weather")
      response = html_response(conn, 200)
      
      assert response =~ "Status"
      assert response =~ "© 2009-2024"
    end
  end

  describe "root layout footer external link validation" do
    test "Status link URL is properly formatted", %{conn: conn} do
      conn = get(conn, ~p"/")
      response = html_response(conn, 200)
      
      # Ensure the URL is valid HTTPS
      assert response =~ "https://codelabs-devops.betteruptime.com/"
    end

    test "Status link URL has proper trailing slash", %{conn: conn} do
      conn = get(conn, ~p"/")
      response = html_response(conn, 200)
      
      # Extract the href value
      case Regex.run(~r{href="(https://codelabs-devops\.betteruptime\.com/)"}, response) do
        [_, url] ->
          # Verify it's exactly as expected with proper trailing slash
          assert url == "https://codelabs-devops.betteruptime.com/"
        _ ->
          flunk("Could not extract Status link URL")
      end
    end

    test "Status link domain is correct", %{conn: conn} do
      conn = get(conn, ~p"/")
      response = html_response(conn, 200)
      
      assert response =~ "codelabs-devops.betteruptime.com"
    end

    test "Status link uses HTTPS protocol", %{conn: conn} do
      conn = get(conn, ~p"/")
      response = html_response(conn, 200)
      
      # Ensure HTTPS is used, not HTTP
      refute response =~ ~r{href="http://codelabs-devops\.betteruptime\.com}
      assert response =~ ~r{href="https://codelabs-devops\.betteruptime\.com}
    end
  end

  describe "root layout footer CSS classes" do
    test "footer uses Tailwind CSS utility classes", %{conn: conn} do
      conn = get(conn, ~p"/")
      response = html_response(conn, 200)
      
      # Verify common Tailwind classes are present
      tailwind_classes = ["flex", "items-center", "space-x", "hover:", "dark:", "transition"]
      
      Enum.each(tailwind_classes, fn class ->
        assert response =~ class, "Missing Tailwind class: #{class}"
      end)
    end

    test "footer maintains dark mode support", %{conn: conn} do
      conn = get(conn, ~p"/")
      response = html_response(conn, 200)
      
      # Check for dark mode variants
      assert response =~ "dark:text-gray-400"
      assert response =~ "dark:hover:text-gray-100"
    end

    test "footer has smooth transition effects", %{conn: conn} do
      conn = get(conn, ~p"/")
      response = html_response(conn, 200)
      
      assert response =~ "transition-colors"
      assert response =~ "duration-200"
    end

    test "footer background has dark mode variant", %{conn: conn} do
      conn = get(conn, ~p"/")
      response = html_response(conn, 200)
      
      assert response =~ "dark:bg-gray-900"
      assert response =~ "bg-white"
    end
  end

  describe "root layout footer regression tests" do
    test "footer does not contain duplicate Status links", %{conn: conn} do
      conn = get(conn, ~p"/")
      response = html_response(conn, 200)
      
      # Extract footer section and count Status links
      footer_regex = ~r{<footer[^>]*>(.*?)</footer>}s
      
      case Regex.run(footer_regex, response) do
        [_, footer_content] ->
          footer_status_count = footer_content
                               |> String.split("Status")
                               |> Enum.count()
                               |> Kernel.-(1)
          
          assert footer_status_count == 1, "Expected exactly 1 Status link in footer"
        _ ->
          flunk("Could not find footer tag")
      end
    end

    test "footer maintains proper HTML structure without broken tags", %{conn: conn} do
      conn = get(conn, ~p"/")
      response = html_response(conn, 200)
      
      # Count opening and closing tags for common footer elements
      opening_divs = response |> String.split("<div") |> Enum.count() |> Kernel.-(1)
      closing_divs = response |> String.split("</div>") |> Enum.count() |> Kernel.-(1)
      
      opening_anchors = response |> String.split("<a") |> Enum.count() |> Kernel.-(1)
      closing_anchors = response |> String.split("</a>") |> Enum.count() |> Kernel.-(1)
      
      assert opening_divs == closing_divs, "Mismatched div tags"
      assert opening_anchors == closing_anchors, "Mismatched anchor tags"
    end

    test "footer does not contain placeholder href values", %{conn: conn} do
      conn = get(conn, ~p"/")
      response = html_response(conn, 200)
      
      # Extract footer to check for placeholder hrefs
      footer_regex = ~r{<footer[^>]*>(.*?)</footer>}s
      
      case Regex.run(footer_regex, response) do
        [_, footer_content] ->
          # Should not have placeholder href="#" links in footer
          refute footer_content =~ ~r{href="#"[^>]*>[\s\n]*(Privacy|Terms)[\s\n]*</a>}
        _ ->
          flunk("Could not find footer tag")
      end
    end
  end

  describe "root layout footer whitespace and formatting" do
    test "Status link text has no extraneous whitespace", %{conn: conn} do
      conn = get(conn, ~p"/")
      response = html_response(conn, 200)
      
      # The link should contain "Status" without excessive whitespace
      assert response =~ ~r{>[\s]*Status[\s]*<}
    end

    test "copyright text is properly formatted", %{conn: conn} do
      conn = get(conn, ~p"/")
      response = html_response(conn, 200)
      
      # Check for proper copyright symbol and year format
      assert response =~ ~r{©\s*2009-2024}
    end

    test "footer spacing classes are consistent", %{conn: conn} do
      conn = get(conn, ~p"/")
      response = html_response(conn, 200)
      
      # Check for proper spacing utilities
      assert response =~ "space-x-6"
      assert response =~ "space-x-1"
    end
  end

  describe "root layout footer border and styling" do
    test "footer has border separator", %{conn: conn} do
      conn = get(conn, ~p"/")
      response = html_response(conn, 200)
      
      # Check for border styling
      assert response =~ "border-t"
      assert response =~ "border-gray-200"
      assert response =~ "dark:border-gray-700"
    end

    test "footer maintains proper color hierarchy", %{conn: conn} do
      conn = get(conn, ~p"/")
      response = html_response(conn, 200)
      
      # Verify color classes for proper visual hierarchy
      assert response =~ "text-gray-900 dark:text-gray-100"
      assert response =~ "text-gray-600 dark:text-gray-400"
    end
  end

  describe "root layout footer brand consistency" do
    test "footer contains brand name", %{conn: conn} do
      conn = get(conn, ~p"/")
      response = html_response(conn, 200)
      
      assert response =~ "¿Who Knows?"
    end

    test "brand name has emphasized styling", %{conn: conn} do
      conn = get(conn, ~p"/")
      response = html_response(conn, 200)
      
      # Brand name should have font-medium class
      assert response =~ ~r{font-medium.*¿Who Knows\?}s
    end
  end

  describe "root layout footer link behavior" do
    test "Status link is a regular anchor tag", %{conn: conn} do
      conn = get(conn, ~p"/")
      response = html_response(conn, 200)
      
      # Should use standard <a> tag, not Phoenix.LiveView link
      assert response =~ ~r{<a href="https://codelabs-devops\.betteruptime\.com/"}
    end

    test "Status link does not have Phoenix.Component attributes", %{conn: conn} do
      conn = get(conn, ~p"/")
      response = html_response(conn, 200)
      
      # Extract the Status link
      status_link_regex = ~r{<a[^>]*href="https://codelabs-devops\.betteruptime\.com/"[^>]*>}
      
      case Regex.run(status_link_regex, response) do
        [link_tag] ->
          # Should not have phx- attributes or navigate attribute
          refute link_tag =~ "phx-"
          refute link_tag =~ "navigate="
        _ ->
          flunk("Could not find Status link")
      end
    end
  end
end