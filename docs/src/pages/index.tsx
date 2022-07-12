import React from 'react';
import Link from '@docusaurus/Link';
import useDocusaurusContext from '@docusaurus/useDocusaurusContext';
import Layout from '@theme/Layout';
import HomepageFeatures from '@site/src/components/HomepageFeatures';
import { FiGithub } from "react-icons/fi"
import Head from '@docusaurus/Head';

function HomepageHeader() {
  const { siteConfig } = useDocusaurusContext();
  return (
    <header className='flex flex-col space-y-5 h-[65vh] md:p-20' style={{ backgroundImage: "url('img/logo.svg')", backgroundSize: "50% auto", backgroundRepeat: "no-repeat", backgroundPosition: "105%" }}>
      <h1 className="text-4xl flex items-center">
        <img src="img/logo.svg" className='mr-2' width="40" alt="" />
        {siteConfig.title}
      </h1>
      <p className="text-2xl max-w-[40%]">{siteConfig.tagline}</p>
      <div className='space-x-5'>
        <Link
          className="button button--primary button--lg"
          to="/docs/getting-started/overview">
          Get Started
        </Link>
        <Link
          className="button button--secondary button--lg"
          href='https://github.com/KRTirtho/fl-query'
        >
          <FiGithub className='mr-1' />
          Github
        </Link>
      </div>
    </header>
  );
}

export default function Home(): JSX.Element {
  const { siteConfig } = useDocusaurusContext();
  return (
    <>
      <Head>
        <link
          rel="apple-touch-icon"
          sizes="180x180"
          href="/apple-touch-icon.png"
        />
        <link
          rel="icon"
          type="image/png"
          sizes="32x32"
          href="/favicon-32x32.png"
        />
        <link
          rel="icon"
          type="image/png"
          sizes="16x16"
          href="/favicon-16x16.png"
        />
        <link rel="manifest" href="/site.webmanifest" />
      </Head>

      <Layout
        title={`${siteConfig.title} - Flutter async data management couldn't be anymore easier`}
        description="Flutter Asynchronous data caching, invalidation, refetching library. React-Query for Flutter. swr for Flutter">
        <HomepageHeader />
        <main>
          <HomepageFeatures />
        </main>
      </Layout>
    </>
  );
}
