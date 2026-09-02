using GreenTestCore;

namespace GreenTestCore.Tests;

public class ExtractTitleFromContentTests
{
    [Fact]
    public void UsesTitleComment_WhenPresent()
    {
        string content = "<!-- title: My Real Title -->\nSome body text.";
        string title = PostsGenerator.ExtractTitleFromContent(content, "some-fallback-name");
        Assert.Equal("My Real Title", title);
    }

    [Fact]
    public void FallsBackToFilename_WhenNoTitleComment()
    {
        string content = "Just some markdown with no title comment at all.";
        string title = PostsGenerator.ExtractTitleFromContent(content, "hello-compost");
        Assert.Equal("Hello Compost", title);
    }

    [Fact]
    public void TitleComment_TrimsWhitespace()
    {
        string content = "<!--   title:   Spaced Out Title   -->\nBody.";
        string title = PostsGenerator.ExtractTitleFromContent(content, "fallback");
        Assert.Equal("Spaced Out Title", title);
    }
}

public class ExtractDateFromContentTests
{
    [Theory]
    [InlineData("Some intro.\n\n*January 15, 2024*\n\nMore text.", "January 15, 2024")]
    [InlineData("Posted on 2024-01-15 by someone.", "2024-01-15")]
    [InlineData("Written January 15, 2024 while it was raining.", "January 15, 2024")]
    public void MatchesKnownDatePatterns(string content, string expectedDate)
    {
        string? date = PostsGenerator.ExtractDateFromContent(content);
        Assert.Equal(expectedDate, date);
    }

    [Fact]
    public void ReturnsNull_WhenNoDatePatternMatches()
    {
        string? date = PostsGenerator.ExtractDateFromContent("No date anywhere in this text at all.");
        Assert.Null(date);
    }

    [Fact]
    public void PrefersStarredDate_OverBareDate_WhenBothPresent()
    {
        // The starred pattern is checked first - matches the priority order
        // generate_posts.py/.js use.
        string content = "*January 15, 2024* is when this was really posted, not 2024-06-01.";
        string? date = PostsGenerator.ExtractDateFromContent(content);
        Assert.Equal("January 15, 2024", date);
    }
}

public class DateSortKeyTests
{
    [Fact]
    public void ParsesFullMonthNameFormat()
    {
        DateTime result = PostsGenerator.DateSortKey("January 15, 2024");
        Assert.Equal(new DateTime(2024, 1, 15), result);
    }

    [Fact]
    public void ParsesIsoFormat()
    {
        DateTime result = PostsGenerator.DateSortKey("2024-01-15");
        Assert.Equal(new DateTime(2024, 1, 15), result);
    }

    [Fact]
    public void ReturnsMinValue_ForUnparseableString()
    {
        DateTime result = PostsGenerator.DateSortKey("not a date at all");
        Assert.Equal(DateTime.MinValue, result);
    }

    [Fact]
    public void NewerDateSortsAfterOlderDate()
    {
        DateTime older = PostsGenerator.DateSortKey("January 15, 2024");
        DateTime newer = PostsGenerator.DateSortKey("2024-06-01");
        Assert.True(newer > older);
    }
}

public class BuildPostsListHtmlTests
{
    [Fact]
    public void ListsEachEntry_WithLinkAndDate()
    {
        var entries = new List<PostsGenerator.PostEntry>
        {
            new("hello-compost", "Hello Compost", "July 05, 2026"),
        };

        string html = PostsGenerator.BuildPostsListHtml(entries);

        Assert.Contains("href=\"post.html?post=hello-compost\"", html);
        Assert.Contains("Hello Compost", html);
        Assert.Contains("(July 05, 2026)", html);
    }

    [Fact]
    public void ShowsPlaceholder_WhenNoEntries()
    {
        string html = PostsGenerator.BuildPostsListHtml(new List<PostsGenerator.PostEntry>());
        Assert.Contains("No posts available yet.", html);
    }
}

public class InsertPostsIntoTemplateTests
{
    [Fact]
    public void ReplacesMarker_WithPostsHtml()
    {
        string template = "<html><body>\n<!-- posts-->\n</body></html>";
        string result = PostsGenerator.InsertPostsIntoTemplate(template, "<p>hi</p>\n");

        Assert.Contains("<p>hi</p>", result);
        Assert.DoesNotContain("<!-- posts-->", result);
    }

    [Fact]
    public void Throws_WhenMarkerMissing()
    {
        string template = "<html><body>no marker here</body></html>";
        Assert.Throws<InvalidOperationException>(
            () => PostsGenerator.InsertPostsIntoTemplate(template, "<p>hi</p>"));
    }
}